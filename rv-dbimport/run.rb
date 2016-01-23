require "logger"
require "yaml"
require "aws-sdk"

TMP_PATH      = File.dirname( __FILE__ ) + "/tmp/"
EXEC_LOG_PATH = File.dirname( __FILE__ ) + "/logs/exec.log"

UNZIP = '/usr/bin/unzip'
MYSQL = '/usr/bin/mysql'
RM    = '/bin/rm'

logger  = Logger.new(EXEC_LOG_PATH)
define  = YAML.load_file( "./define.yml" )
restore_list = define["restore_list"]

date_str = `date +%Y%m%d`
date_str = date_str.strip
datetime_str = `date +%Y%m%d-%H%M%S`
datetime_str = datetime_str.strip
logger.info "rv-dbimport Started #{datetime_str}."

restore_list.each do |product_name, restore_options|
  # 
  # download from s3
  # 
  Aws.config.update(
    profile: "rv-backup",
    region: "ap-northeast-1",
    credentials: Aws::Credentials.new("AKIAI65ONY5QS4KD6ELQ", "85weUHiANE0BLIcOAOba6J4h0mn8GHfjmvVlOOCR")
  )
  s3      = Aws::S3::Client.new
  bucket  = "rv-backup"

  zip_file_path   = "#{TMP_PATH}#{product_name}.#{date_str}.sql.zip"
  unzip_file_path = "#{TMP_PATH}#{product_name}.#{date_str}*.sql"
  s3.list_objects(
    bucket: bucket,
    prefix: "#{product_name}/#{product_name}.#{date_str}"
  ).contents.each do |obj|
    File.open(zip_file_path, "w") do |file|
      s3.get_object(
        bucket: "rv-backup", 
        key: obj.key
      ) do |chunk|
        file.write(chunk)
      end
    end
  end

  # 
  # unzip
  # 
  unzip_cmd = <<-EOH
    #{UNZIP} -f -P #{restore_options["zip_password"]} #{zip_file_path}
  EOH
  `#{unzip_cmd}`
  if $? != 0
    logger.error "Failed to unzip: #{unzip_cmd}"
    exit( 1 )
  end

  # 
  # mysql
  # 
  db_options  = restore_options["db"]
  tmp_db_name = db_options["database"] + "_tmp"
  drop_db_cmd =<<-EOH
    #{MYSQL} \
      -u#{db_options["user"]} \
      -p#{db_options["password"]} \
      -h#{db_options["host"]} \
      -P#{db_options["port"]} \
      -e "drop database #{db_options['database']};"
  EOH
  create_db_cmd = <<-EOH
    #{MYSQL} \
      -u#{db_options["user"]} \
      -p#{db_options["password"]} \
      -h#{db_options["host"]} \
      -P#{db_options["port"]} \
      -e "create database #{db_options['database']};"
  EOH
  unzip_file_name = `file #{unzip_file_path} | tail | cut -d":" -f1`
  unzip_file_name = unzip_file_name.strip
  restore_db_cmd =<<-EOH
    #{MYSQL} \
      -u#{db_options["user"]} \
      -p#{db_options["password"]} \
      -h#{db_options["host"]} \
      -P#{db_options["port"]} \
      #{db_options['database']} \
      < #{unzip_file_name}
  EOH
  `#{drop_db_cmd}`
  `#{create_db_cmd}`
  `#{restore_db_cmd}`
  if $? != 0
    logger.error "Failed to restore: #{restore_db_cmd}"
    exit( 1 )
  end

  # 
  # remove
  # 
  `#{RM} -f #{TMP_PATH}*`

end

logger.info "rv-dbimport Finished #{datetime_str}."