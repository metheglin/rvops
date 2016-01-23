require "logger"
require "yaml"
require "aws-sdk"

TMP_PATH      = File.dirname( __FILE__ ) + "/tmp/"
EXEC_LOG_PATH = File.dirname( __FILE__ ) + "/logs/exec.log"

ZIP         = '/usr/bin/zip'
MYSQL_DUMP  = '/usr/bin/mysqldump'
RSYNC       = '/usr/bin/rsync'

logger  = Logger.new(EXEC_LOG_PATH)
define  = YAML.load_file( "./define.yml" )
db_list = define["db_list"]

datetime_str = `date +%Y%m%d-%H%M%S`
datetime_str = datetime_str.strip
logger.info "Crystal Backup Started #{datetime_str}."

db_list.each do |db_name, db_options|
  # 
  # mysqldump
  # 
  tmp_file_name = "#{db_name}.#{datetime_str}.sql"
  tmp_file_path = TMP_PATH + tmp_file_name
  dump_cmd = <<-EOH
    #{MYSQL_DUMP} \
      -u#{db_options["user"]} \
      -p#{db_options["password"]} \
      -h#{db_options["host"]} \
      -P#{db_options["port"]} \
      #{db_options["database"]} \
      > #{tmp_file_path}
  EOH
  `#{dump_cmd}`
  puts $?
  if $? != 0
    logger.error "Failed to mysqldump: #{dump_cmd}"
    exit( 1 )
  end

  # 
  # zip
  # 
  tmp_zip_file_name = "#{tmp_file_name}.zip"
  tmp_zip_file_path = "#{tmp_file_path}.zip"
  zip_cmd = <<-EOH
    #{ZIP} -P #{db_options["zip_password"]} #{tmp_zip_file_path} #{tmp_file_path}
  EOH
  `#{zip_cmd}`
  if $? != 0
    logger.error "Failed to zip: #{zip_cmd}"
    exit( 1 )
  end

  # 
  # backup
  # 
  Aws.config.update(
    profile: "rv-backup",
    region: "ap-northeast-1",
  )
  s3 = Aws::S3::Client.new
  File.open( tmp_zip_file_path ) do |file|
    s3.put_object(
      bucket: "rv-backup",
      body: file,
      key: "#{db_name}/#{tmp_zip_file_name}"
    )
  end

  # 
  # remove
  # 
  File.unlink(tmp_file_path)
  File.unlink(tmp_zip_file_path)

end

logger.info "Crystal Backup Finished #{datetime_str}."