if (rs.next()) {
    for(int i=1; i<=8; i++)
        System.out.println(rs.getString(i));
}
