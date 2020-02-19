module Travis::API::V3
  class Models::RequestConfig < Model
  end

  class Models::RequestYamlConfig < Model
  end

  class Models::RequestRawConfig < Model
  end

  class Models::RequestRawConfiguration < Model
    belongs_to :request
    belongs_to :raw_config, foreign_key: :request_raw_config_id, class_name: 'Models::RequestRawConfig'
  end

  class Models::Request < Model
    def self.columns
      super.reject { |c| c.name == 'payload' }
    end

    belongs_to :commit
    belongs_to :pull_request
    belongs_to :repository
    belongs_to :owner, polymorphic: true
    belongs_to :config, foreign_key: :config_id, class_name: 'Models::RequestConfig'
    belongs_to :yaml_config, foreign_key: :yaml_config_id, class_name: 'Models::RequestYamlConfig'
    has_many   :raw_configurations, -> { order 'request_raw_configurations.id' }, class_name: 'Models::RequestRawConfiguration'
    has_many   :raw_configs, through: :raw_configurations, class_name: 'Models::RequestRawConfig'
    has_many   :builds
    serialize  :config
    serialize  :payload
    has_many   :messages, as: :subject

    def branch_name
      commit.branch_name if commit
    end

    def config=(config)
      raise unless ENV['RACK_ENV'] == 'test'
      config = Models::RequestConfig.new(repository_id: repository_id, key: 'key', config: config)
      super(config)
    end

    def config
      record = super
      config = record&.config_json if record.respond_to?(:config_json)
      config ||= record&.config
      config ||= read_attribute(:config) if has_attribute?(:config)
      config ||= {}
      config.deep_symbolize_keys! if config.respond_to?(:deep_symbolize_keys!)
      config
    end

    def yaml_config
      super
    end

    def payload
      raise "[deprecated] Reading request.payload}"
    end
  end
end
