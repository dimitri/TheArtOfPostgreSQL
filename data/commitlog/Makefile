all: postgres pgloader ;

postgres:
	#git clone --filter=tree:0 https://git.postgresql.org/git/postgresql.git
	# A bare clone (as below) needs an explicit target directory name: git's
	# default naming for a --bare clone keeps the ".git" suffix (this would
	# otherwise land in ./postgres.git), but tooling/taop/gitlog.lisp expects
	# a "postgresql" directory (matching the original, now-commented-out
	# clone URL above) — and book queries such as queries/05-data-types/
	# 23-pg-data-types-101/11_01.sql filter on `project = 'postgresql'`, so
	# that expected name is fixed on the Lisp side, not worth changing.
	git clone --bare --filter=tree:0 https://github.com/postgres/postgres.git postgresql

pgloader:
	git clone --filter=tree:0 https://github.com/dimitri/pgloader.git
