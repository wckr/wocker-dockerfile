<?php
if ( isset( $_POST['name'] ) ) {
    create();
}

if ( isset( $_POST['install'] ) ) {
    install();
}

if ( isset( $_POST['delete'] ) ) {
    delete();
}
?>
<!DOCTYPE html>
<html lang="en-US">
<head>
<meta charset="UTF-8" />
<title>Hosts</title>
</head>
<body>
<form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>"> 
Create Vhost: <input type="text" name="name">
<input type="submit" value="name">
</form>
<form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>"> 
Create Vhost+WordPress Install: <input type="text" name="install">
<input type="submit" value="install">
</form>
<form method="post" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>"> 
<?php button(); ?>
</form>
</body>
</html>
<?php
function create($host) {
if ($_POST["name"] != '') {
$_POST["name"];
$create = ('vhost '. $_POST["name"]);
shell_exec($create);
}
}
function install($host) {
if ($_POST["install"] != '') {
$_POST["install"];
$install = ('wp-install '. $_POST["install"]);
shell_exec($install);
}
}
function delete($host) {
if ($_POST["delete"] != '') {
$_POST["delete"];
$sed = 'sudo sed -i -e \''.'s/127.0.0.1\t'.$_POST["delete"].'//g\''.' /etc/hosts'; 
$sed2 = 'sudo sed -i -e \''.'/^$/d\''. ' /etc/hosts';
shell_exec($sed);
shell_exec($sed2);
shell_exec('sudo rm -rf /etc/apache2/sites-enabled/'.$_POST["delete"].'.*');
shell_exec('sudo rm -rf /var/www/'.$_POST["delete"]);
}
}
function button($host) {
$dir = "/var/www";
$list = array_slice(scandir($dir), 2);
$count = 1;
echo ("<table border=1px solid>");
foreach ($list as $host) {
if ($host != "html") {
echo ("<tr>");
echo ("<td>[". $count . "]</td><td><input type=\"submit\" name=\"delete\" value=\"$host\"></td>");
echo ("</tr>");
$count++;
}
}
echo ("</table>");
}
?>
