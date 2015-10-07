<?php

if (ob_get_level() == 0) ob_start();

for ($i = 0; $i < 10; $i++) {
    echo 'aaaaaaaaaa';

    ob_flush();
    flush();
    sleep(2);
}

echo "Done.";

ob_end_flush();

?>