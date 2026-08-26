<?php defined('BASEPATH') or exit('No direct script access allowed');

// Add custom values by settings them to the $config array.
// Example: $config['smtp_host'] = 'smtp.gmail.com';
// @link https://codeigniter.com/user_guide/libraries/email.html

// ─────────────────────────────────────────────────────────────
// Masáže Karin — konfigurácia sa číta priamo z env premenných.
//
// Oficiálny docker-entrypoint.sh tento súbor prepisuje pri štarte
// kontajnera, ale staršie verzie base image ho negenerovali vôbec
// a zostal default 'mail' → PHP mail() → "sendmail: not found".
// Toto čítanie cez getenv() funguje nezávisle od entrypointu.
// ─────────────────────────────────────────────────────────────

$env = static function (string $key, $default = null) {
    $value = getenv($key);
    return ($value === false || $value === '') ? $default : $value;
};

$config['useragent'] = 'Easy!Appointments';
$config['protocol'] = $env('MAIL_PROTOCOL', 'mail'); // 'mail' | 'smtp' | 'sendmail'
$config['mailtype'] = 'html'; // or 'text'

if ($config['protocol'] === 'smtp') {
    $config['smtp_host'] = $env('MAIL_SMTP_HOST', '');
    $config['smtp_user'] = $env('MAIL_SMTP_USER', '');
    $config['smtp_pass'] = $env('MAIL_SMTP_PASS', '');
    $config['smtp_port'] = (int) $env('MAIL_SMTP_PORT', 587);
    $config['smtp_crypto'] = $env('MAIL_SMTP_CRYPTO', 'tls'); // 'tls' | 'ssl'
    $config['smtp_auth'] = filter_var($env('MAIL_SMTP_AUTH', 'TRUE'), FILTER_VALIDATE_BOOLEAN);
    $config['smtp_debug'] = (string) (int) $env('MAIL_SMTP_DEBUG', 0);
    $config['smtp_timeout'] = 30;
}

$from_address = $env('MAIL_FROM_ADDRESS');
if ($from_address !== null) {
    $config['from_address'] = $from_address;
    $config['from_name'] = $env('MAIL_FROM_NAME', 'Karina Masáže');
}

$reply_to = $env('MAIL_REPLY_TO_ADDRESS');
if ($reply_to !== null) {
    $config['reply_to'] = $reply_to;
}

$config['crlf'] = "\r\n";
$config['newline'] = "\r\n";
