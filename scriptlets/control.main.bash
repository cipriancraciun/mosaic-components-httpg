#!/dev/null


test "${_harness_fingerprint:-??}" == b829e0d2a9fa7b9e5edbe03821032e42 || { echo "[ee] incompatible (or missing) harness; aborting!" >&2 ; exit 1 ; }
test "${_library_fingerprint:-??}" == 36dcfdc332deccb97efc6a1fc14c1cbc || { echo "[ee] incompatible (or missing) library; aborting!" >&2 ; exit 1 ; }
test "${1:-??}" == '--'
shift


if ! test "${#}" -ge 2 ; then
	_abort main "usage: ${_self_path} <action> <deployment-path> <arguments>*"
fi

_action="${1}"
_deployment_path="${2}"
shift 2


_deployment_bundles_path="${_deployment_path}/bundles"
_deployment_erlang_path="${_deployment_path}/erlang"
_deployment_data_path="${_deployment_path}/data"

_erl_path=''
_erl_run_argv=(
	+Bd +Ww
	-env ERL_CRASH_DUMP /dev/null
	-env ERL_LIBS "${_deployment_erlang_path}/lib"
	-noshell -noinput
	-config "${_deployment_erlang_path}/lib/mosaic_httpg/priv/mosaic_httpg.config"
	-mnesia dir "\"${_deployment_data_path}/mnesia\""
	-run mosaic_httpg_app run
)


_bundles_token='6f51b85b25e3dabdf1822800f279602c'
_bundles_base_url="http://data.volution.ro/ciprian/${_bundles_token}"
_ez_bundle_names=(
	amqp_client
	goodies
	misultin
	mochiweb
	mosaic_httpg
	rabbit_common
	rabbit
	rabbit_management_agent
	rabbit_management
	rabbit_mochiweb
	transcript
	vme
	webmachine
)


__fetch_bundles () {
	_set_failure_message 'failed fetching bundles'
	test "${#}" -eq 0
	local __bundle_name='' __bundle_path='' __bundle_url=''
	for __bundle_name in "${_ez_bundle_names[@]}" ; do
		__bundle_path="${_deployment_bundles_path}/${__bundle_name}.ez"
		__bundle_url="${_bundles_base_url}/${__bundle_name}.ez"
		if ! test -e "${__bundle_path}" ; then
			_curl_fetch_file "${__bundle_path}" "${__bundle_url}"
		else
			_trace info main "bundle already exists: \`${__bundle_path}\`; skipping!"
		fi
	done
	_unset_failure_message
	return 0
}


__deploy_erlang_applications () {
	_set_failure_message 'failed deploying erlang applications'
	test "${#}" -eq 0
	if test -e "${_deployment_erlang_path}/lib" ; then
		_trace warn main "erlang applications already deployed; removing and redeploying!"
		rm -Rf -- "${_deployment_erlang_path}/lib"
	fi
	_create_folder "${_deployment_erlang_path}/lib"
	local __bundle_name='' __bundle_path=''
	for __bundle_name in "${_ez_bundle_names[@]}" ; do
		__bundle_path="${_deployment_bundles_path}/${__bundle_name}.ez"
		_extract_archive "${_deployment_erlang_path}/lib" "${__bundle_path}" zip
	done
	_unset_failure_message
	return 0
}


_deploy () {
	_set_failure_message 'failed deploying'
	test "${#}" -eq 0
	_create_folder "${_deployment_path}"
	_create_folder "${_deployment_bundles_path}"
	_create_folder "${_deployment_erlang_path}"
	_create_folder "${_deployment_data_path}"
	__fetch_bundles
	__deploy_erlang_applications
	_unset_failure_message
	return 0
}


_run () {
	_set_failure_message 'failed running'
	if ! test -e "${_deployment_path}" -a -e "${_deployment_erlang_path}" -a -e "${_deployment_data_path}" ; then
		_abort main "nothing deployed at the specified path: \`${_deployment_path}\`"
	fi
	if test -z "${_erl_path}" ; then
		_resolve_executable _erl_path erl
	fi
	cd -- "${_deployment_path}"
	_run_exec "${_erl_path}" "${_erl_run_argv[@]}"
	_abort main "fallen through..."
	_unset_failure_message
}


case "${_action}" in
	( deploy )
		if ! test "${#}" -eq 0 ; then
			_abort main "usage: ${_self_path} deploy <deployment-path>"
		fi
		_deploy
		_exit 0
	;;
	( run )
		if ! test "${#}" -eq 0 ; then
			_abort main "usage: ${_self_path} run <deployment-path>"
		fi
		_run
	;;
	( * )
		_abort main "unknown action: \`${_action}\`"
	;;
esac


_abort main "fallen through..."