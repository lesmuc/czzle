<?php


ini_set('error_reporting', E_ALL | E_STRICT);
ini_set('display_errors', 1);

require_once 'config.php';
require_once 'lib/EchoNest/lib/EchoNest/Autoloader.php';

EchoNest_Autoloader::register();
$echonest = new EchoNest_Client();
$echonest->authenticate($echoNestApiKey);

/**
 * Find an artist for a given difficulty level
 *
 * @param integer $level        the difficulty level
 * @param object  $echonest     echonest instance
 * @param integer $i            indicates the current search iteration
 */
function findArtist($level, $echonest, $i = 0)
{
    if ($i > 100) {
        die('sorry, no artist found');
    }

    $familiarity = 0.9 - ($level/10);

    $results = $echonest->getArtistApi()->search(array(
        'genre' => 'classical',
        'min_familiarity' => $familiarity,
        'artist_start_year_before' => 1870,
        'sort' => 'familiarity-desc'
    ));

    $rand = rand(0, count($results) - 1);
    $artist = $results[$rand];

    $location = $echonest->getArtistApi()->setId($artist['id'])->getProfile(array(
        'bucket' => 'artist_location'
    ));

    $country = $location['artist_location']['country'];
    $city = $location['artist_location']['city'];

    // filter the USA because we get wrong results from there -> this is just a hack
    if ($country == 'United States'
        || empty($city)
        || empty($country)
    ) {
        return findArtist($level, $echonest, ++$i);
    }

    return $location;
}

/**
 * Get a song for a given difficulty level
 *
 * @param integer $level        the difficulty level
 * @param object  $echonest     echonest instance
 * @param integer $i            indicates the current search iteration
 */
function getSong($level, $echonest, $i = 0)
{
    if ($i > 100) {
        die('sorry, no song found');
    }

    $artist = findArtist($level, $echonest);

    $songs = $echonest->getSongApi()->search(array(
        'artist_id' => $artist['id'],
        'bucket' => array('id:spotify-WW', 'tracks')
    ));

    $songsWithTrx = array();

    foreach ($songs as $song) {

        if (count($song['tracks']) > 0) {
            foreach ($song['tracks'] as $i => $track) {
                $song['tracks'][$i]['foreign_id'] = preg_replace('~^spotify\-WW~', 'spotify', $song['tracks'][$i]['foreign_id']);
            }

            $songsWithTrx[] = $song;
        }
    }

    $songs = $songsWithTrx;

    if (count($songs) == 0) {
        return getSong($level, $echonest, ++$i);
    }

    $rand = rand(0, count($songs) - 1);
    $song = $songs[$rand];
    $rand = rand(0, count($song['tracks']) - 1);

    return array(
        'artist' => $artist,
        'song'   => $song['tracks'][$rand]
    );
}

$level = isset($_GET['level']) ? (int) $_GET['level'] : 1;

$song = getSong($level, $echonest);
$echonest->deAuthenticate();

if ($song === false) {
    die('this software sucks');
}

header('Content-Type: application/json');
echo json_encode($song);


