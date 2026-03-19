try {
    con = DriverManager.getConnection(url, user, password);
    st = con.createStatement();
    rs = st.executeQuery("SELECT name, date, url, extra FROM races LIMIT 1;");
    
    if (rs.next()) {
        System.out.println(" race: " + rs.getString("name"));
        System.out.println(" date: " + rs.getString("date"));
        System.out.println("  url: " + rs.getString("url"));
        System.out.println("extra: " + rs.getString("url"));
        System.out.println();
    }
    
} catch (SQLException ex) {
  // logger code
} finally {
  // closing code
}
