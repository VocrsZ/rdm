class Rdm::CLI::DiffPackage
  class << self
    def run(opts = {})
      Rdm::CLI::DiffPackage.new(opts).run
    end
  end

  attr_reader :path, :revision
  def initialize(path:, revision:)
    @path      = path
    @revision = revision
  end

  def run
    puts Rdm::Handlers::DiffPackageHandler.handle(path: path, revision: revision)
  rescue Rdm::Errors::GitRepositoryNotInitialized
    puts "Git repository is not initialized. Use `git init .`"
  rescue Rdm::Errors::GitCommandError => e
    puts e.message
  end
end