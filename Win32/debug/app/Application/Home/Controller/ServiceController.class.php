<?php
/**
 * Created by PhpStorm.
 * User: lobtao
 * Date: 2018-08-07
 * Time: 20:27
 */
namespace Home\Controller;


use Think\Controller;

class ServiceController extends Controller
{

    private function callFunc($func, $args) {
        $params = explode('_', $func, 2);
        if (count($params) != 2) throw new \Exception('�����������');

        $svname = ucfirst($params[0]);
        $classname = 'app\\service\\' . $svname . 'Service';;
        $funcname = $params[1];
        if (!class_exists($classname)) throw new \Exception('��' . $svname . '�����ڣ�����');
        $object = new $classname();
        if (!method_exists($object, $funcname)) throw new \Exception($svname . '�в�����' . $funcname . '����');
        $data = call_user_func_array(array($object, $funcname), $args);
        return $data;
    }

    function index() {
        $result = array(
            'retid'  => 1,
        );
        try {
            $ret = $this->callFunc($_GET['f'], json_decode($_GET['p'],true));
            $result['data'] = $ret;
        } catch (\Exception $ex) {
            $result['retid'] = 0;
            $result['retmsg'] = $ex->getMessage();
        }
        echo json_encode($result);
    }
}