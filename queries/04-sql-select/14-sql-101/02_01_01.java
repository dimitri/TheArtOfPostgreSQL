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
  }
} catch (SQLException ex) {
  // logger code
} finally {
  // closing code
}
