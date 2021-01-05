# frozen_string_literal: true

class DarwinCore
  class Error < RuntimeError; end
  class FileNotFoundError < Error; end
  class UnpackingError < Error; end
  class InvalidArchiveError < Error; end
  class CoreFileError < Error; end
  class ExtensionFileError < Error; end
  class GeneratorError < Error; end
  class ParentNotCurrentError < Error; end
  class EncodingError < Error; end

  class InvalidMetadataError < Error
    def initialize(errors)
      super(errors.map { |e| e.message }.join(';'))
    end
  end
end
