<%# Need to use this trick to include the beginning of the jsp file %>
<%= "<%!" %>
// This is the security salt that must match the value set in the BigBlueButton server
String salt = "<%= node[:bbb][:salt] %>";

// This is the URL for the BigBlueButton server
String BigBlueButtonURL = "<%= node[:bbb][:server_url] %>/bigbluebutton";
<%= "%\>" %>

