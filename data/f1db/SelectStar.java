import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Level;
import java.util.logging.Logger;

public class SelectStar {

    public static void main(String[] args) {

        Connection con = null;
        Statement st = null;
        ResultSet rs = null;
    
        String url = "jdbc:postgresql://localhost/f1db";
        String user = "dim";
        String password = "none";

        try {
            con = DriverManager.getConnection(url, user, password);
            st = con.createStatement();
            rs = st.executeQuery("SELECT * FROM races LIMIT 1;");

            if (rs.next()) {
                System.out.println(rs.getInt("raceid"));
                System.out.println(rs.getInt("year"));
                System.out.println(rs.getInt("round"));
                System.out.println(rs.getInt("circuitid"));
                System.out.println(rs.getString("name"));
                System.out.println(rs.getString("date"));
                System.out.println(rs.getString("time"));
                System.out.println(rs.getString("url"));
                System.out.println(rs.getString("extra"));
            }

        } catch (SQLException ex) {
            Logger lgr = Logger.getLogger(SelectStar.class.getName());
            lgr.log(Level.SEVERE, ex.getMessage(), ex);

        } finally {
            try {
                if (rs != null) {
                    rs.close();
                }
                if (st != null) {
                    st.close();
                }
                if (con != null) {
                    con.close();
                }

            } catch (SQLException ex) {
                Logger lgr = Logger.getLogger(SelectStar.class.getName());
                lgr.log(Level.WARNING, ex.getMessage(), ex);
            }
        }
    }
}
