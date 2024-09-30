<?php
require_once "config.php";

// Images directory.
$img_base = "images/";
// End config.

$list = "";
$i = 0;

$maps_a = array(
    0 => 'Eastern Kingdoms',
    1 => 'Kalimdor',
    2 => 'UnderMine',
    13 => 'Test zone',
    17 => 'Kalidar',
    30 => 'Alterac Valley',
    33 => 'Shadowfang Keep',
    34 => 'The Stockade',
    35 => 'Stormwind Prison',
    36 => 'Deadmines',
    37 => 'Plains of Snow',
    43 => 'Wailing Caverns',
    44 => 'Monastery Interior',
    47 => 'Razorfen Kraul',
    48 => 'Blackfathom Deeps',
    70 => 'Uldaman',
    90 => 'Gnomeregan',
    109 => 'Sunken Temple',
    129 => 'Razorfen Downs',
    169 => 'Emerald Forest',
    189 => 'Scarlet Monastery',
    209 => 'Zul\'Farrak',
    229 => 'Blackrock Spire',
    230 => 'Blackrock Depths',
    249 => 'Onyxias Lair',
    269 => 'Caverns of Time',
    289 => 'Scholomance',
    309 => 'Zul\'Gurub',
    329 => 'Stratholme',
    349 => 'Maraudon',
    369 => 'Deeprun Tram',
    389 => 'Ragefire Chasm',
    409 => 'The Molten Core',
    429 => 'Dire Maul',
    449 => 'Alliance PVP Barracks',
    450 => 'Horde PVP Barracks',
    451 => 'Development Land',
    469 => 'Blackwing Lair',
    489 => 'Warsong Gulch',
    509 => 'Ruins of Ahn\'Qiraj',
    529 => 'Arathi Basin',
    531 => 'Temple of Ahn\'Qiraj',
    533 => 'Naxxramas',
);

$def = array(
    'character_race' => array(
        1 => 'Human',
        2 => 'Orc',
        3 => 'Dwarf',
        4 => 'Night&nbsp;Elf',
        5 => 'Undead',
        6 => 'Tauren',
        7 => 'Gnome',
        8 => 'Troll',
        9 => 'Goblin',
    ),

    'character_class' => array(
        1 => 'Warrior',
        2 => 'Paladin',
        3 => 'Hunter',
        4 => 'Rogue',
        5 => 'Priest',
        7 => 'Shaman',
        8 => 'Mage',
        9 => 'Warlock',
        11 => 'Druid',
    ),
);

$user_chars = "#[^a-zA-Z0-9_\-]#";
$email_chars = "/^[^0-9][A-z0-9_]+([.][A-z0-9_]+)*[@][A-z0-9_]+([.][A-z0-9_]+)*[.][A-z]{2,4}$/";

$result = "";
$realmstatus = "<FONT COLOR=yellow>Unknown</FONT>";
$uptime = "N/A";
$accounts = "N/A";
$totalchars = "N/A";
date_default_timezone_set("Asia/Shanghai");
$now = date("H:i:s", time());

function make_players_array()
{
    global $con, $c_db, $pl_array, $maps_a;
    $i = 0;
    mysqli_query($con, "SET NAMES 'utf8'");
    $data = $con->query("SELECT * FROM " . $con->real_escape_string($c_db) . ".characters WHERE `online`='1' ORDER BY `name`");
    if ($data->num_rows > 0) {
        while ($result = $data->fetch_assoc()) {
            $char_data = ($result['level']);
            $char_gender = ($result['gender']);
            if (strlen($maps_a[$result['map']]) > 0) {
                $res_pos = $maps_a[$result['map']];
            } else {
                $res_pos = "Unknown Zone";
            };

            $pl_array[$i] = array($result['name'], $result['race'], $result['class'], $char_data, $res_pos, $char_gender);
            $i++;
        }
        return $i;
    }
}

if (!$con) {
    $result = "> Unable to connect to database: " . $con->error;
} else {
    /*    $qry = $con->query("select address from " . real_escape_string($r_db) . ".realmlist where id = 1");
        if ($qry)
        {
            while ($row = mysql_fetch_assoc($qry))
            {
                $realmip = $row['address'];
            }
        };
    */
    unset($qry);
    $data = $con->query("select name from " . $con->real_escape_string($r_db) . ".realmlist where id = 1");
    if ($data->num_rows > 0) {
        while ($result = $data->fetch_assoc()) {
            $realmname = $result['name'];
        }
    }
    if (!$sock = @fsockopen($realmip, $realmport, $num, $error, 3)) {
        $realmstatus = "<FONT COLOR=red>Offline</FONT>";
        $realmstatus = $error . $realmip . $realmport;
    } else {
        $realmstatus = "<FONT COLOR=green>Online</FONT>";
        fclose($sock);
    };

    unset($data);
    $data = $con->query("SELECT * FROM " . $con->real_escape_string($r_db) . ".uptime ORDER BY `starttime` DESC LIMIT 1");
    if ($data->num_rows > 0) {
        while ($result = $data->fetch_array(MYSQLI_BOTH)) {
            if ($result['uptime'] > 86400) {
                $uptime = round(($result['uptime'] / 24 / 60 / 60) ) . " Days";
            } elseif ($result['uptime'] > 3600) {
                $uptime = round(($result['uptime'] / 60 / 60)) . " Hours";
            } else {
                $uptime = round(($result['uptime'] / 60)) . " Min";
            }
        }
    }
    unset($data);
    $data = $con->query("select Count(id) from " . $con->real_escape_string($r_db) . ".account",);
    if ($data->num_rows > 0) {
        while ($result = $data->fetch_assoc()) {
            $accounts = $result['Count(id)'];
        }
    };

    unset($data);
    $data = $con->query("select Count(guid) from " . $con->real_escape_string($c_db) . ".characters");
    if ($data->num_rows > 0) {
        while ($result = $data->fetch_assoc()) {
            $totalchars = $result['Count(guid)'];
        }
    };

    $onlineplayers = make_players_array();

    if (!$sort = &$_GET['s']) $sort = 0;
    if (!$flag = &$_GET['f']) $flag = 0;
    if ($flag == 0) {
        $flag = 1;
        $sort_type = '<';
    } else {
        $flag = 0;
        $sort_type = '>';
    }
    $link = $_SERVER['PHP_SELF'] . "?f=" . $flag . "&s=";

    if (!empty($pl_array)) {
        usort($pl_array, create_function('$a, $b', 'if ( $a[' . $sort . '] == $b[' . $sort . '] ) return 0; if ( $a[' . $sort . '] ' . $sort_type . ' $b[' . $sort . '] ) return -1; return 1;'));
    }


    while ($i < $onlineplayers) {
        $name = $pl_array[$i][0];
        $race = $pl_array[$i][1];
        $class = $pl_array[$i][2];
        $res_race = $def['character_race'][$race];
        $res_class = $def['character_class'][$class];
        $lvl = $pl_array[$i][3];
        $loc = $pl_array[$i][4];
        $gender = $pl_array[$i][5];
        $tmpnum = ($i + 1);
        $list .= "<tr>
        <td>$tmpnum</td>
        <td>$name</td>
        <td align=center><img alt=$res_race src='" . $img_base . "race/" . $race . "-$gender.gif' height=18 width=18></td>
        <td align=center><img alt=$res_class src='" . $img_base . "class/$class.gif' height=18 width=18></td>
        <td align=center>$lvl</td>
        <td>$loc</td>
        </tr>";
        $i++;
    }
};
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8"/>
    <title>Server Information - brotalnia's repack</title>
    <style>
        hr {
            border: 0;
            box-sizing: content-box;
            height: 0;
            margin-top: 10px;
            margin-bottom: 10px;
            border-top: 1px solid #eee;
        }

        .h1, h1 {
            font-family: inherit;
            font-weight: 500;
            line-height: 1.1;
            color: inherit;
            margin-top: 20px;
            margin-bottom: 10px;
            font-size: 36px;
        }

        h2 {
            font-size: 50px;
        }

        img {
            border: 0;
            vertical-align: middle;
        }

        *, :after, :before {
            -webkit-box-sizing: border-box;
            -moz-box-sizing: border-box;
            box-sizing: border-box;
        }

        html {
            font-size: 10px;
            -webkit-tap-highlight-color: transparent;
        }

        a, body {
            color: #fff;
        }

        body, html {
            overflow: visible;
            font-family: Proxima Nova, sans-serif;
        }

        table, th, td {
            border: 1px solid black;
            border-collapse: collapse;
        }

        th, td {
            padding: 5px;
            text-align: left;
        }

        body {
            margin: 0;
            height: 100%;
            width: 99%;
            background-color: #000000;
        }

        #wrapper {
            position: relative;
            height: 100%;
            width: 100%;
        }

        #header {
            -webkit-box-sizing: content-box;
            -moz-box-sizing: content-box;
            box-sizing: content-box;
            background-color: rgb(3, 34, 76);
            color: white;
            text-align: center;
            padding: 5px;
        }

        #nav {
            -webkit-box-sizing: content-box;
            -moz-box-sizing: content-box;
            box-sizing: content-box;
            position: absolute;
            line-height: 30px;
            background-color: #033553;
            height: calc(100vh - 38px);
            height: -o-calc(100vh - 38px); /* opera */
            height: -webkit-calc(100vh - 38px); /* google, safari */
            height: -moz-calc(100vh - 38px); /* firefox */
            width: 150px;
            float: left;
            padding: 5px;
            color: rgb(255, 165, 0);
            font-weight: bold;
            font-size: 15px;
        }

        #nav a:link {
            color: rgb(255, 165, 0);
        }

        #nav a:visited {
            color: rgb(255, 165, 0);
        }

        #nav a:hover {
            color: #7FFF00;
        }

        #nav a:active {
            color: rgb(255, 165, 0);
        }

        #section {
            -webkit-box-sizing: content-box;
            -moz-box-sizing: content-box;
            box-sizing: content-box;
            background-image: url('images/<?php echo $cmangos_core ?>.jpg');
            background-size: cover;
            width: calc(100% - 175px);
            width: -o-calc(100% - 175px); /* opera */
            width: -webkit-calc(100% - 175px); /* google, safari */
            width: -moz-calc(100% - 175px); /* firefox */
            height: calc(100vh - 30px);
            height: -o-calc(100vh - 30px); /* opera */
            height: -webkit-calc(100vh - 30px); /* google, safari */
            height: -moz-calc(100vh - 30px); /* firefox */
            float: left;
            padding-left: 175px;
        }

        #footer {
            background-color: rgb(3, 34, 76);
            color: white;
            clear: both;
            text-align: center;
            padding: 5px;
            font-size: 16px;
        }

        #list {
            -webkit-box-sizing: content-box;
            -moz-box-sizing: content-box;
            box-sizing: content-box;
            background: rgba(16, 16, 16, .4) !important;
            background-blend-mode: multiply;
            max-width: 1170px;
            width: 80%;
            font-size: 20px;
        }

        #info {
            font-size: 20px;
        }
    </style>
</head>
<body>

<div id="wrapper">
    <div id="nav">
        <!--<a href="" style="text-decoration:none"><img src="images/youtube.png" alt="[1]" width="16" height="16"> 关于我们</a><br>
        <hr>-->
        <a href="registration.php" style="text-decoration:none"><img src="images/mangos.png" alt="[2]" width="16" height="16">
            创建账号</a><br>
        <a href="index.php" style="text-decoration:none"><img src="images/lfg.png" alt="[3]" width="16" height="16">
            服务器信息</a><br>
        <hr>
        <!--<div align="center">
        <a href="http://www.ownedcore.com/forums/world-of-warcraft/world-of-warcraft-emulator-servers/wow-emu-general-releases/613280-elysium-core-1-12-repack-including-mmaps-optional-vendors.html" style="text-decoration:none"><img src="images/ocbanner.png" alt="OwnedCore" width="88" height="31"></a><br>
        </div>-->
    </div>
    <div id="section">
        <h2>服务器: <?php if (isset($realmname)) {
                echo $realmname;
            } else {
                echo "Lightbringer";
            } ?></h2>
        <p id="info">状态: <?php echo $realmstatus; ?>
            <br>
            服务器时间: <?php echo $now; ?>
            <br>
            服务器在线时间: <?php echo $uptime; ?>
            <br><br>
            账号总数: <?php echo $accounts; ?>
            <br>
            角色总数: <?php echo $totalchars; ?>
        </p>
        <br><br><br>
        <div id="list">
            <center>在线玩家: <?php if (isset($onlineplayers)) {
                    echo $onlineplayers;
                } else {
                    echo "0";
                } ?></center>
            <br>
            <table width="100%" border="0" style="color:Azure">
                <tr>
                    <td align="left" width=50></td>
                    <td align="left" width=60>角色名</td>
                    <td align="center" width=40>种族</td>
                    <td align="center" width=40>职业</td>
                    <td align="center" width=40>等级</td>
                    <td align="left" width=100>当前地区</td>
                </tr>
                <?php echo $list ?>
            </table>
        </div>
    </div>
    <div id="footer">
        Powered by Big Pineapple <a target="_blank"
                                    href="http://wpa.qq.com/msgrd?v=3&uin=50839213&site=qq&menu=yes"><img border="0"
                                                                                                          src=""
                                                                                                          alt="点击这里给我发消息"
                                                                                                          title="点击这里给我发消息"/></a>
    </div>
</div>
</body>
</html>