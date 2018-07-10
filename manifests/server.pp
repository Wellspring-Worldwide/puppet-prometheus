# class to manage the actual prometheus server
# this is a private class that gets called from the init.pp
class prometheus::server (
  String $configname                                            = $prometheus::configname,
  String $user                                                  = $prometheus::user,
  String $group                                                 = $prometheus::group,
  Array $extra_groups                                           = $prometheus::extra_groups,
  Variant[Prometheus::Absolutepath, String] $bin_dir           = $prometheus::bin_dir,
  Variant[Prometheus::Absolutepath, String] $shared_dir        = $prometheus::shared_dir,
  String $version                                               = $prometheus::version,
  String $install_method                                        = $prometheus::install_method,
  Variant[Prometheus::HTTPUrl, Prometheus::HTTPSUrl, String] $download_url_base = $prometheus::download_url_base,
  String $download_extension                                    = $prometheus::download_extension,
  String $package_name                                          = $prometheus::package_name,
  String $package_ensure                                        = $prometheus::package_ensure,
  String $config_dir                                            = $prometheus::config_dir,
  Variant[Prometheus::Absolutepath, String] $localstorage       = $prometheus::localstorage,
  String $config_template                                       = $prometheus::config_template,
  String $config_mode                                           = $prometheus::config_mode,
  Hash $global_config                                           = $prometheus::global_config,
  Array $rule_files                                             = $prometheus::rule_files,
  Array $scrape_configs                                         = $prometheus::scrape_configs,
  Array $remote_read_configs                                    = $prometheus::remote_read_configs,
  Array $remote_write_configs                                   = $prometheus::remote_write_configs,
  Variant[Array,Hash] $alerts                                   = $prometheus::alerts,
  Array $alert_relabel_config                                   = $prometheus::alert_relabel_config,
  Array $alertmanagers_config                                   = $prometheus::alertmanagers_config,
  String $storage_retention                                     = $prometheus::storage_retention,
  Variant[Prometheus::Absolutepath, String] $env_file_path      = $prometheus::env_file_path,
  Hash $extra_alerts                                            = $prometheus::extra_alerts,
  Boolean $service_enable                                       = $prometheus::service_enable,
  String $service_ensure                                        = $prometheus::service_ensure,
  Boolean $manage_service                                       = $prometheus::manage_service,
  Boolean $restart_on_change                                    = $prometheus::restart_on_change,
  String $init_style                                            = $prometheus::init_style,
  String $extra_options                                         = $prometheus::extra_options,
  Hash $config_hash                                             = $prometheus::config_hash,
  Hash $config_defaults                                         = $prometheus::config_defaults,
  String $os                                                    = $prometheus::os,
  Optional[String] $download_url                                = $prometheus::download_url,
  String $arch                                                  = $prometheus::real_arch,
  Boolean $manage_group                                         = $prometheus::manage_group,
  Boolean $purge_config_dir                                     = $prometheus::purge_config_dir,
  Boolean $manage_user                                          = $prometheus::manage_user,
) inherits prometheus {

  if( versioncmp($version, '1.0.0') == -1 ){
    $real_download_url = pick($download_url,
      "${download_url_base}/download/${version}/${package_name}-${version}.${os}-${arch}.${download_extension}")
  } else {
    $real_download_url = pick($download_url,
      "${download_url_base}/download/v${version}/${package_name}-${version}.${os}-${arch}.${download_extension}")
  }
  $notify_service = $restart_on_change ? {
    true    => Service['prometheus'],
    default => undef,
  }

  $config_hash_real = assert_type(Hash, deep_merge($config_defaults, $config_hash))

  file { "${config_dir}/rules":
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    mode   => $config_mode,
  }

  $extra_alerts.each | String $alerts_file_name, Hash $alerts_config | {
    prometheus::alerts { $alerts_file_name:
      alerts   => $alerts_config,
    }
  }
  $extra_rule_files = suffix(prefix(keys($extra_alerts), "${config_dir}/rules/"), '.rules')

  if ! empty($alerts) {
    prometheus::alerts { 'alert':
      alerts   => $alerts,
      location => $config_dir,
    }
    $_rule_files = concat(["${config_dir}/alert.rules"], $extra_rule_files)
  }
  else {
    $_rule_files = $extra_rule_files
  }
  contain prometheus::install
  contain prometheus::config
  contain prometheus::run_service
  contain prometheus::service_reload

  Class['prometheus::install']
  -> Class['prometheus::config']
  -> Class['prometheus::run_service']
  -> Class['prometheus::service_reload']
}
