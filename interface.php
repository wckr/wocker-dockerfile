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
function create() {
if ($_POST["name"] != '') {
$_POST["name"];
$create = ('vhost '. $_POST["name"]);
shell_exec($create);
}
}
function install() {
if ($_POST["install"] != '') {
$_POST["install"];
$install = ('wp-install '. $_POST["install"]);
shell_exec($install);
}
}
function delete() {
if ($_POST["delete"] != '') {
$_POST["delete"];
$sed = 'sed -e \''.'s/127.0.0.1\t'.$_POST["delete"].'//g\''.' /etc/hosts > /etc/hosts2';
$sed2 = 'sed -e \''.'/^$/d\''. ' /etc/hosts > /etc/hosts3';
shell_exec($sed);
shell_exec('cp -f /etc/hosts2 /etc/hosts');
shell_exec($sed2);
shell_exec('cp -f /etc/hosts3 /etc/hosts');
shell_exec('rm -rf /etc/apache2/sites-enabled/'.$_POST["delete"].'.*');
shell_exec('rm -rf /var/www/'.$_POST["delete"]);
shell_exec('sudo service apache2 force-reload');
}
}
function button() {
$dir = "/var/www";
$list = array_slice(scandir($dir), 2);
$count = 1;
echo ("<table border=1px solid>");
foreach ($list as $host) {
if (($host != "html")&&($host != "wordpress")&&($host != "wp-cli.yml") {
echo ("<tr>");
echo ("<td>[". $count . "]</td><td><input type=\"submit\" name=\"delete\" value=\"$host\"></td>");
echo ("</tr>");
$count++;
}
}
echo ("</table>");
}
?>
