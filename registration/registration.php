<?php
require_once "config.php";

$user_chars = "#[^a-zA-Z0-9_\-]#";
$email_chars = "/^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,})$/";
$realmip = "";
$result = "";

$regname = 'ADMINISTRATOR'; //  (create gmlvl 6 account, enable soap in mangosd.conf - soap uses a dummy gm account to handle registration)
$regpass = 'ADMINISTRATOR';
$soap_ac_command = "account create {USERNAME} {PASSWORD}";
$soap_asa_command = 'account set addon {USERNAME} {EXPANSION}';

// Define SOAP client
$client = new SoapClient(NULL,
    array(
        "location" => "http://$soaphost:$soapport",
        "uri" => "urn:MaNGOS",
        "style" => SOAP_RPC,
        'login' => $regname,
        'password' => $regpass
    ));
$data = $con->query("select address from " . $con->real_escape_string($r_db) . ".realmlist where id = 1");
if ($data->num_rows > 0) {
    while ($result = $data->fetch_assoc()) {
        $realmip = $result['address'];
    }
}
if (!empty($_POST)) {
    if ((empty($_POST["username"])) || (empty($_POST["password"])) || (empty($_POST["email"]))) {
        $result = "> 请输入所有要求的信息";
    } else {
        $username = strtoupper($_POST["username"]);
        $password = strtoupper($_POST["password"]);
        $password2 = strtoupper($_POST["password2"]);
        $email = strtoupper($_POST["email"]);
        if (strlen($username) < 4) {
            $result = "> 用户名太短";
        };
        if (strlen($username) > 14) {
            $result = "> 用户名太长";
        };
        if (strlen($password) < 3) {
            $result = ">密码太短";
        };
        if (strlen($password) > 12) {
            $result = "> 密码太长";
        };
        if ($password != $password2) {
            $result = "> 两次密码不匹配";
        };
        if (strlen($email) < 10) {
            $result = "> 邮件太短";
        };
        if (strlen($email) > 50) {
            $result = "> 邮箱太长";
        };
        if (preg_match($user_chars, $username)) {
            $result = "> 用户名有非法字符";
        };
        if (preg_match($user_chars, $password)) {
            $result = "> 密码有非法字符";
        };
        if (!preg_match($email_chars, $email)) {
            //$result = "> 电子邮箱格式不正确";
        };
        if (strlen($result) < 1) {
            $username = $con->real_escape_string($username);
            $password = $con->real_escape_string($password);
            $email = $con->real_escape_string($email);
            unset($data);
            $data = $con->query("select username from " . $con->real_escape_string($r_db) . ".account where username = '" . $username . "'");
            $existing_username = "";
            if ($data->num_rows > 0) {
                while ($row = $data->fetch_assoc()) {
                    $existing_username = $row["username"];
                }
            }
            if ($existing_username == strtoupper($_POST['username'])) {
                $result = "> 用户名已存在";
            } else {
                unset($data);
                $existing_email = "";
                $data = $con->query("select email from " . $con->real_escape_string($r_db) . ".account where email = '" . $email . "'");
                if ($data->num_rows > 0) {
                    while ($row = $data->fetch_assoc()) {
                        $existing_email = $row["email"];
                    }
                }
                if ($existing_email == strtoupper($_POST['email'])) {
                    $result = ">邮箱已被使用";
                } else {
                    unset($data);
                    $soap_ac_command = str_replace('{USERNAME}', $username, $soap_ac_command);
                    $soap_ac_command = str_replace('{PASSWORD}', $password, $soap_ac_command);
                    $soap_asa_command = str_replace('{USERNAME}', $username, $soap_asa_command);
                    $soap_asa_command = str_replace('{EXPANSION}', $expansion, $soap_asa_command);
                    try {
                        $res = $client->executeCommand(new SoapParam($soap_ac_command, "command"));
                        $res = $client->executeCommand(new SoapParam($soap_asa_command, "command"));
                        $data = $con->query("update " . $con->real_escape_string($r_db) . ".account set email='".$con->real_escape_string($email)."' where username = '" . $username . "'");
                        $result = ">账号注册成功！";
                        unset($data);
                    } catch (Exception $e) {
                        echo $e;
                        $result = "> 注册失败!";
                    }
                };
            };
        };
    };
};
?>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8"/>
    <title>Account Creation - brotalnia's repack</title>
    <style>
        hr, img {
            border: 0
        }

        hr {
            box-sizing: content-box;
            height: 0;
            margin-top: 10px;
            margin-bottom: 10px;
            border-top: 1px solid #eee
        }

        .h1, .h2, .h3, .h4, .h5, .h6, h1, h2, h3, h4, h5, h6 {
            font-family: inherit;
            font-weight: 500;
            line-height: 1.1;
            color: inherit
        }

        .h1, .h2, .h3, h1, h2, h3 {
            margin-top: 20px;
            margin-bottom: 10px
        }

        .h4, .h5, .h6, h4, h5, h6 {
            margin-top: 10px;
            margin-bottom: 10px
        }

        .h1, h1 {
            font-size: 36px
        }

        .content, .wrapper .main {
            width: 100%;
            margin: 0 auto
        }


        img {
            vertical-align: middle
        }

        button, input, optgroup, select, textarea {
            color: inherit;
            font: inherit;
            margin: 0
        }

        button, html input[type=button], input[type=reset], input[type=submit] {
            -webkit-appearance: button;
            cursor: pointer
        }

        button[disabled], html input[disabled] {
            cursor: default
        }

        button::-moz-focus-inner, input::-moz-focus-inner {
            border: 0;
            padding: 0
        }

        *, :after, :before {
            -webkit-box-sizing: border-box;
            -moz-box-sizing: border-box;
            box-sizing: border-box
        }

        html {
            font-size: 10px;
            -webkit-tap-highlight-color: transparent
        }

        a:focus, a:hover {
            color: #5a5a5a;
            text-decoration: underline
        }

        p {
            margin: 0 0 10px
        }

        dl, ol, ul {
            margin-top: 0
        }

        address, dl {
            margin-bottom: 20px
        }

        code, kbd {
            padding: 2px 4px;
            font-size: 90%
        }

        code {
            color: #c7254e;
            background-color: #f9f2f4;
            border-radius: 4px
        }

        .my-btn, .start-btn {
            text-transform: uppercase
        }

        a, body {
            color: #fff
        }

        .red {
            color: red
        }

        .content {
            position: relative;
            padding: 0 50px;
            max-width: 960px;
            top: 50%;
            transform: translate(0, -50%);
            transition: all .2s ease-out;
            z-index: 1
        }

        .content-big {
            max-width: 1170px
        }

        .arrow-btn:hover, .form .mana-button:hover, .start-btn:active, .start-btn:focus, .start-btn:hover {
            box-shadow: 0 0 10px 1px red, 0 0 10px 1px red inset
        }

        .form {
            margin: 20px 0 0
        }

        .form input {
            display: block;
            padding: 0 15px;
            font: 300 1.5em Roboto, sans-serif;
            margin-bottom: 10px;
            border: 1px solid #fff
        }

        .form .mana-button {
            color: red;
            font: 500 1.5em Roboto, sans-serif;
            border: 1px solid red
        }

        .form .mana-button:hover {
            border-color: red
        }

        button {
            transition: all ease .5s
        }

        button:focus {
            outline: 0
        }

        .cols {
            margin-left: -15px;
            margin-right: -15px
        }

        .cols:after {
            display: table
        }

        [class*=cols-col-] {
            position: relative;
            float: left;
            width: 100%;
            padding-left: 15px;
            padding-right: 15px
        }

        .cols-col-50 {
            width: 50%
        }

        .news-list-tr-sm {
            opacity: .8
        }

        .link {
            display: inline-block;
            text-decoration: underline;
            font-size: 14px
        }

        .link:focus, .link:hover, .my-btn, .nav li a, a.btn {
            text-decoration: none
        }

        .my-btn {
            display: block;
            border: 1px solid #fff;
            text-align: center;
            padding: 4px;
            margin-bottom: 5px
        }

        .my-btn:focus, .my-btn:hover {
            background: #fff;
            color: #101010;
            text-decoration: none
        }

        .dark-background {
            background: rgba(16, 16, 16, .4) !important;
            background-blend-mode: multiply;
            overflow: hidden
        }

        body, html {
            overflow: visible;
            font-family: Proxima Nova, sans-serif
        }

        .manas h4 {
            line-height: 40px;
            font: 600 2em RobotoB, sans-serif !important;
            font-size: 24px;
            border-bottom: 2px solid #000;
            padding: 5px 20px 14px
        }

        .manas h4 span {
            color: #999
        }

        .manas .mana-input {
            min-height: 40px;
            background: rgba(255, 255, 255, 0.3);
            margin-left: 20px;
            width: 85%;
            padding: 10px 15px;
            outline: 0;
            border: 0;
            text-transform: none
        }

        .manas .mana-button {
            height: 40px;
            background: #101010;
            width: auto;
            margin-left: 20px !important;
            margin-bottom: 30px !important;
            padding: 10px 15px;
            outline: 0;
            border: 1px solid #000;
            color: #b9b9b9;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            font: 300 1em Roboto, sans-serif;
            text-decoration: none
        }

        .manas .mana-button:hover {
            color: #fff
        }

        .mana-label {
            line-height: 30px;
            padding-left: 20px;
            padding-right: 20px;
            float: left;
            display: inline-block;
            font-size: 16px
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

        #regresult {
            font-size: 16px;
            font-weight: bold;
            padding-left: 20px;
        }

        body {
            margin: 0;
            height: 100%;
            width: 99%;
            background-color: #000000;
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
        <div align="center">
            <!--<a href="http://www.ownedcore.com/forums/world-of-warcraft/world-of-warcraft-emulator-servers/wow-emu-general-releases/613280-elysium-core-1-12-repack-including-mmaps-optional-vendors.html" style="text-decoration:none"><img src="images/ocbanner.png" alt="OwnedCore" width="88" height="31"></a><br>-->
        </div>
    </div>
    <div id="section">

        <div class="content content-big">
            <div class="manas">
                <div class="cols">
                    <div class="row dark-background">
                        <div class="cols-col-50">
                            <h4>创建账号</h4>
                            <div class="mana-label">
                                <p>
                                    欢迎来到<?php echo $realm_name ?>，原汁原味！！<br>
                                    <strong>同一IP恶意注册多次将被永久禁止登录</strong><br>
                                    <span class="red">请输入以下信息完成注册</span>
                                </p">
                            </div>
                            <form name="form" class="form" method="post" action="registration.php">
                                <br>
                                <input id="form_username" name="username" required="required" class="mana-input"
                                       placeholder="用户名" type="text">
                                <input id="form_password_first" name="password" required="required" class="mana-input"
                                       placeholder="密码" type="password">
                                <input id="form_password_second" name="password2" required="required" class="mana-input"
                                       placeholder="确认密码" type="password">
                                <input id="form_email" name="email" required="required" class="mana-input"
                                       placeholder="电子邮件" type="email">
                                <div>
                                    <br>
                                    <p class="red" id="regresult"><?php if (isset($result)) {
                                            echo $result;
                                        } ?></p>
                                    <button type="submit" id="form_save" name="form[save]" class="mana-button"
                                            style="border-color:#f60;">提交注册
                                    </button>
                                </div>
                                <input id="form__token" name="form[_token]"
                                       value="7XaIY8g-l6N51oQuzMtr8Ph3RJk6C9DEAjs-BpJUAbA" type="hidden"></form>
                        </div>
                        <!--<div class="cols-col-50">-->
                        <!--<h4>游戏说明</h4>-->
                        <!--<div class="mana-label">-->
                        <!--<a href="" class="my-btn">-->
                        <!--下载客户端并配置服务器地址-->
                        <!--</a>-->
                        <!--  <h3>注册账号来怀旧WOW70年代</h3>-->
                        <!--<ol>-->
                        <!--<li>下载wow2.43客户端：<a href="https://www.king607267.store:60332/sharing/hNpzQQZNm">点我直达下载链接</a></li>-->
                        <!--<li>用记事本打开WOW客户端根目录下的realmlist.wtf文件<br><code>set realmlist -->
                        <?php //if(isset($realmip)){ echo $realmip; } else { echo "127.0.0.1";} ?><!--</code></li>-->
                        <!--<li>记住：点击 wow.exe 启动游戏而不是点击其它</li>-->
                        <!--<li>好了，开始冒险吧！</li>-->
                        <!--</ol>-->
                        <!--</div>-->
                        <!--</div>-->
                    </div>
                </div>
            </div>
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