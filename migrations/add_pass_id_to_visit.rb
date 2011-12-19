require 'dm-migrations/migration_runner'
require 'dm-postgres-adapter'
DataMapper.setup(:default, ENV['DATABASE_URL'])
DataMapper::Logger.new(STDOUT, :debug)
DataMapper.logger.debug( "Starting Migration" )

migration 1, :add_pass_id_to_visit do 
  up do 
    modify_table :visits do
      add_column :pass_id, Integer
    end
  end
  down do 
    modify_table :visits do
      drop_column :pass_id
    end
  end
end


if $0 == __FILE__
  if $*.first == "down"
    migrate_down!
  else
    migrate_up!
  end
end


