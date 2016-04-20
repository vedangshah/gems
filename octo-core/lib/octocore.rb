require 'cequel'
require 'yaml'
require 'logger'

require 'octocore/version'
require 'octocore/config'
require 'octocore/models'
require 'octocore/counter'
require 'octocore/utils'
require 'octocore/trendable'
require 'octocore/baseline'
require 'octocore/trends'
require 'octocore/kldivergence'
require 'octocore/scheduler'
require 'octocore/schedeuleable'
require 'octocore/helpers'
require 'octocore/kafka_bridge'
require 'octocore/stats'

# The main Octo module
module Octo

  # Connect using the provided configuration. If you want to extend Octo's connect
  #   method you can override this method with your own. Just make sure to make
  #   a call to self._connect(configuration) so that Octo also connects
  # @param [Hash] configuration The configuration hash
  def self.connect(configuration)
    self._connect(configuration)
  end

  # Connect by reading configuration from the provided file
  # @param [String] config_file Location of the YAML config file
  def self.connect_with_config_file(config_file)
    config = YAML.load_file(config_file).deep_symbolize_keys
    self.connect(config)
  end


  # A low level method to connect using a configuration
  # @param [Hash] configuration The configuration hash
  def self._connect(configuration)

    load_config configuration

    self.logger.info('Octo booting up.')

    # Establish Cequel Connection
    connection = Cequel.connect(configuration)
    Cequel::Record.connection = connection

    # Establish connection to cache server
    default_cache = {
        host: '127.0.0.1', port: 6379
    }
    cache_config = Octo.get_config(:redis, default_cache)
    Cequel::Record.update_cache_config(*cache_config.values_at(:host, :port))

    # Establish connection to statsd server if required
    if configuration.has_key?(:statsd)
      statsd_config = configuration[:statsd]
      set_config :stats, Statsd.new(*statsd_config.values)
      end

    self.logger.info('I\'m connected now.')
    require 'octocore/callbacks'

    self.logger.info('Setting callbacks.')

  end

  # Creates a logger for Octo
  def self.logger
    unless @logger
      @logger = Logger.new(Octo.get_config(:logfile, $stdout)).tap do |log|
        log.progname = name
      end
    end
    @logger
  end

end