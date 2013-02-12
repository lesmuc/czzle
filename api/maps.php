<?php

ini_set('error_reporting', E_ALL | E_STRICT);
ini_set('display_errors', 1);


// calling this script via GET uses same example parameters (used for development)
if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    $_POST['latitude'] = 12.21679;
    $_POST['artist_id'] = 'ARIZUYR11F3462EBC5';
    $_POST['longitude'] = 42.65012;
    $_POST['artist_location']['city'] = 'St. Ulrich';
    $_POST['artist_location']['country'] = 'Italy';
}


require_once 'config.php';
require_once 'lib/EchoNest/lib/EchoNest/Autoloader.php';

EchoNest_Autoloader::register();
$echonest = new EchoNest_Client();
$echonest->authenticate($echoNestApiKey);


$artist = $echonest->getArtistApi()->setId($_POST['artist_id'])->getProfile(array(
    'bucket' => 'biographies'
));



$longestTxt = '';

foreach ($artist['biographies'] as $b) {
    if (mb_strlen($b['text']) > mb_strlen($longestTxt)) {
        $longestTxt = $b['text'];
    }
}

$echonest->deAuthenticate();

$origins = $_POST['latitude'] . ',' . $_POST['longitude'];
$destinations = $_POST['artist_location']['city'] . ' ' . $_POST['artist_location']['country'];
$destinations = urlencode($destinations);


$url = 'http://maps.googleapis.com/maps/api/distancematrix/json?origins=' . $origins . '&destinations=' . $destinations . '&sensor=false';


$ch = curl_init($url);

$options = array(
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => array('Content-type: application/json'),
    CURLOPT_ENCODING, "UTF-8"
);

curl_setopt_array($ch, $options);
$result = curl_exec($ch);
$json = json_decode($result);


// extra geocodes for the artists location
$url = 'http://maps.googleapis.com/maps/api/geocode/json?address=' . $destinations . '&sensor=false';
$ch = curl_init($url);
curl_setopt_array($ch, $options);
$result = curl_exec($ch);
$extra = json_decode($result);
$location = $extra->results[0]->geometry->location;
$location->city = $_POST['artist_location']['city'] . ', ' . $_POST['artist_location']['country'];



// remove the leading disambiguation info
$longestTxt = trim(preg_replace('~^.*\(disambiguation\)\.~Usi', '', $longestTxt));

$distance = $json->rows[0]->elements[0]->distance;
$distance->value = round($distance->value/1000);
$distance->bio = $longestTxt;
$distance->location = $location;
$distance->artist = $artist['name'];

header('Content-Type: application/json');
echo json_encode($distance);
