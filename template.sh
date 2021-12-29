#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(cd $(dirname $0); pwd)
ARGS_NUM=1

# 外部コマンド用
declare -a REQUIRED_CMD=()	# コマンドが存在するか確認したいものをこの配列に登録する
declare -a CMDS				# REQUIRED_CMDに登録したコマンドを連想配列でアクセスする
							# currentやSCRIPT_DIRに置いてあるコマンドも${CMDS["cmd"]} で使用できる

# version definition
VER_MAJOR=0		# 破壊的な修正、大きな機能追加
VER_MINOR=0		# バグ修正、小さな機能追加
VER_BUILD=0		# リファクタリング等の動作に影響のない変更

# help
function usage
{
	cat <<EOF
Usage: ${SCRIPT_NAME} [options]... [args]...
	ここに説明を記載

Args:
	XXX		[XXX]の説明
Options:
	-h, --help		ヘルプ表示
	-v, --version	バージョン表示

Version:
	$(version)
EOF
}

# version出力
function version
{
	echo "${VER_MAJOR}.${VER_MINOR}.${VER_BUILD}"
}

# コマンドのパスを返す
# current dir->SCRIPT_DIR->globaleの順で検索
# $1 cmd
function get_cmd_path
{
	local dirs=("./$1" "${SCRIPT_DIR}/$1" "$1")
	for cmd in ${dirs[@]}; do
		if (type $cmd > /dev/null 2>&1); then
			echo $cmd
			return
		fi
   	done
}

# 必要なコマンドの確認
function check_command_exist
{
	local not_exist=()
	for cmd in ${REQUIRED_CMD[@]}; do
		local path=$(get_cmd_path $cmd)
		if [ -n "$[path]" ]; then
			local key=$(basename ${cmd} | sed -re 's/\..*$//')
			CMDS["${key}"]="${path}"
		else
			not_exist=("${not_exist[@]}" "${cmd}")
		fi
	done

	if [ ${#not_exist[@]} -ne 0 ]; then
		err_msg "following command is required. [${not_exist[@]}]"
		exit 1
	fi
}

# エラーメッセージ
# $1 メッセージ
function err_msg
{
	ESC=$(printf '\033')
	echo "${SCRIPT_NAME}: ${ESC}[31m$1${ESC}[m" 1>&2
}



# option parse
args=()
current_opt=""
for OPT in "$@"
do
	case $OPT in
		"-h" | "--help" )
			usage
			exit 0
		;;
		"-v" | "--version" )
			version
			exit 0
		;;
		*)
			if [ -n "${current_opt}" ]; then
				case $current_opt in
					*)
						err_msg "option is not fully supported ${current_opt}"
						exit 1
					;;
				esac
				current_opt=""
			else
				args=("${args[@]}" "$OPT")
			fi
		;;
	esac
done

# 必要コマンドの確認
check_command_exist

# 引数の数をチェック
if [ ${#args[@]} -ne ${ARGS_NUM} ]; then
	err_msg "number of args not match. number of args is ${ARGS_NUM}."
	exit 1
fi

## -- メイン処理 --
echo $args

exit 0
