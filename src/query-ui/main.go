package main

import (
	"context"
	"embed"
	"flag"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed frontend/dist/*
var frontendFS embed.FS

// frontendRoot rebases the embedded FS so that frontend/dist/index.html is
// served at "/" instead of "/frontend/dist/index.html".
func frontendRoot() fs.FS {
	sub, err := fs.Sub(frontendFS, "frontend/dist")
	if err != nil {
		log.Fatalf("Failed to load embedded frontend: %v", err)
	}
	return sub
}

type Server struct {
	db            *pgxpool.Pool
	router        *chi.Mux
	toc           *TOC
	queries       *QueryIndex
	queryParams   QueryParams
	starterKit    []StarterKitPage
	starterKitDir string
	port          int
}

func main() {
	port := flag.Int("port", 8042, "HTTP port to listen on")
	dbURL := flag.String("db", "", "PostgreSQL connection URL")
	queriesDir := flag.String("queries", "../queries", "Path to queries directory")
	tocFile := flag.String("toc", "../toc.txt", "Path to toc.txt")
	paramsFile := flag.String("params", "../query-params.json", "Path to query-params.json (\\set injection for parameter-example queries)")
	starterKitDir := flag.String("starter-kit", "../starter-kit", "Path to the starter-kit/ directory (one page per NN-name.md file, plus an img/ subdirectory)")
	healthcheck := flag.Bool("healthcheck", false, "Probe /health on -port and exit 0/1 (used as Docker HEALTHCHECK; the scratch image has no shell/wget)")
	flag.Parse()

	if *healthcheck {
		runHealthcheckProbe(*port)
		return
	}

	if *dbURL == "" {
		*dbURL = os.Getenv("DATABASE_URL")
		if *dbURL == "" {
			*dbURL = "postgresql://taop:taop@localhost:5433/taop"
		}
	}

	// Make paths absolute if relative
	if !filepath.IsAbs(*queriesDir) {
		wd, _ := os.Getwd()
		*queriesDir = filepath.Join(wd, *queriesDir)
	}
	if !filepath.IsAbs(*tocFile) {
		wd, _ := os.Getwd()
		*tocFile = filepath.Join(wd, *tocFile)
	}
	if !filepath.IsAbs(*paramsFile) {
		wd, _ := os.Getwd()
		*paramsFile = filepath.Join(wd, *paramsFile)
	}
	if !filepath.IsAbs(*starterKitDir) {
		wd, _ := os.Getwd()
		*starterKitDir = filepath.Join(wd, *starterKitDir)
	}

	log.Printf("Connecting to PostgreSQL: %s", *dbURL)
	db, err := connectDB(context.Background(), *dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	if err := db.Ping(context.Background()); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	log.Println("✓ PostgreSQL connected")

	// Parse TOC
	log.Printf("Parsing TOC from: %s", *tocFile)
	toc, err := ParseTOC(*tocFile)
	if err != nil {
		log.Fatalf("Failed to parse TOC: %v", err)
	}
	log.Printf("✓ Loaded %d parts, %d chapters", len(toc.Parts), toc.TotalChapters())

	// Index queries
	log.Printf("Indexing queries from: %s", *queriesDir)
	queries, err := IndexQueries(*queriesDir)
	if err != nil {
		log.Fatalf("Failed to index queries: %v", err)
	}
	log.Printf("✓ Indexed %d queries", len(queries.ByPath))

	// Load query-params.json (\set injection for the book's parameter-example
	// queries); a missing file just means the feature is unused, not an error.
	log.Printf("Loading query params from: %s", *paramsFile)
	queryParams, err := LoadQueryParams(*paramsFile)
	if err != nil {
		log.Fatalf("Failed to load query params: %v", err)
	}
	log.Printf("✓ Loaded %d query param overrides", len(queryParams))

	// The starter-kit directory is 6 hand-picked pages, not lab
	// infrastructure — missing is a fatal error (there'd be nothing for
	// /starter-kit.html to show), but a malformed individual page still
	// yields whatever cells parsed rather than blocking startup, since
	// ParseCells can't itself fail.
	log.Printf("Loading starter kit from: %s", *starterKitDir)
	starterKit, err := LoadStarterKit(*starterKitDir)
	if err != nil {
		log.Fatalf("Failed to load starter-kit directory: %v", err)
	}
	log.Printf("✓ Loaded %d starter-kit pages", len(starterKit))

	srv := &Server{
		db:            db,
		router:        chi.NewRouter(),
		toc:           toc,
		queries:       queries,
		queryParams:   queryParams,
		starterKit:    starterKit,
		starterKitDir: *starterKitDir,
		port:          *port,
	}

	srv.setupRoutes()

	addr := fmt.Sprintf(":%d", *port)
	log.Printf("\n🚀 Starting query-ui on http://localhost:%d", *port)
	log.Println("   Open your browser and navigate to the URL above")
	log.Printf("\nDatabase: %s\n", *dbURL)

	if err := http.ListenAndServe(addr, srv.router); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}

// runHealthcheckProbe performs a local /health GET and exits 0 (success) or 1
// (failure), following os.Exit's behavior with Docker's HEALTHCHECK. It exists
// because the final image is FROM scratch: there is no wget/curl/shell to
// express the healthcheck as a shell command, so the binary checks itself.
func runHealthcheckProbe(port int) {
	client := http.Client{Timeout: 3 * time.Second}
	resp, err := client.Get(fmt.Sprintf("http://localhost:%d/health", port))
	if err != nil || resp.StatusCode != http.StatusOK {
		os.Exit(1)
	}
	os.Exit(0)
}

func (s *Server) setupRoutes() {
	// Frontend assets (embedded, rebased so index.html serves at "/"). This
	// is a local dev tool rebuilt frequently (a new binary = new HTML/JS
	// baked in), and browsers cache "/" by default with no version query
	// string or ETag scheme to invalidate against — a rebuilt container
	// otherwise keeps serving an already-loaded, now-stale page until a
	// hard refresh, which reads as a UI fix "not working" when it's really
	// just not been fetched yet.
	fileServer := http.FileServer(http.FS(frontendRoot()))
	noCache := func(h http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")
			h.ServeHTTP(w, r)
		})
	}
	s.router.Handle("/", noCache(fileServer))

	// API: Health check
	s.router.Get("/health", s.handleHealth)

	// API: TOC structure
	s.router.Get("/api/toc", s.handleTOC)
	s.router.Get("/api/part/{partNum}", s.handlePart)

	// API: Queries
	s.router.Get("/api/query/{part}/{chapter}/{section}/{queryID}", s.handleQueryFile)
	s.router.Post("/api/query/execute", s.handleQueryExecute)
	s.router.Post("/api/query/explain", s.handleQueryExplain)

	// API: Starter kit — list of pages, then one page's cells by slug
	s.router.Get("/api/starter-kit", s.handleStarterKit)
	s.router.Get("/api/starter-kit/{slug}", s.handleStarterKitPage)

	// starter-kit/img/*.png referenced from the pages' Markdown (e.g.
	// ![...](img/fig-pubs-knn.png)) — mounted from disk like queries/,
	// toc.txt and query-params.json, not embedded in the binary.
	s.router.Handle("/starter-kit-assets/*", noCache(http.StripPrefix(
		"/starter-kit-assets/", http.FileServer(http.Dir(s.starterKitDir)),
	)))

	// Catch-all for every other embedded asset (starter-kit.html, and
	// /static/* if that's ever used) — registered last so it can never
	// shadow a specific API route above, regardless of how chi prioritizes
	// wildcard vs. exact patterns internally.
	s.router.Handle("/*", noCache(fileServer))
}
