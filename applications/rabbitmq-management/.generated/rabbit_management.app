{application, rabbit_management,
 [{description, "RabbitMQ Management Console"},
  {vsn, "2.2.0"},
  {modules, [rabbit_mgmt_app]}, %% TODO generate automatically. NB: _app needed!
  {registered, []},
  {mod, {rabbit_mgmt_app, []}},
  {env, [{http_log_dir, none}]},
  {applications, [kernel, stdlib, rabbit, rabbit_mochiweb, webmachine,
                  rabbit_management_agent]}]}.
