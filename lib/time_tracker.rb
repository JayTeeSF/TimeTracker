class TimeTracker
  INSTANCES = {}

  def self.help
   puts <<-EOM
     irb -r ./app/lib/time_tracker.rb
     > TimeTracker.clear
     > t = TimeTracker.new("1")
     > t.start :one
     > TimeTracker.find("1") == t
      => true
     > TimeTracker.clear
     > TimeTracker.find("1") == t
      => false
     > TimeTracker.store("1", t)
     > TimeTracker.find("1") == t
      => true
     > t.finish(:one)
     > t.took(:one)
      => 56.28791809082031
     > t.to_s
      => "[[:one, {:start=>1519870588.9845388, :finish=>1519870645.272457, :took=>56.28791809082031}]]"
     > t.section_keys
      => [:one]
     > t.started_last
      => [:one, 1519870588.9845388] # the start time
     > t.finished_first
      => [:one, 1519870645.272457] # the finish time
   EOM
  end

  def self.clear
    INSTANCES.clear
  end

  def self.find(name)
    INSTANCES[name]
  end

  def self.store(name, object)
    warn "overwriting tracker: #{name} -> #{object.sections.inspect}" if INSTANCES[name]
    INSTANCES[name] = object
  end

  START_KEY = :start
  FINISH_KEY = :finish
  TOOK_KEY = :took
  attr_reader :name, :sections

  def initialize(name)
    @name = name
    @sections = {}
    TimeTracker.store(@name, self)
  end

  def start(key, as_of=Time.now.to_f)
    fail("Attempt to (re-)start immutable section #{key.inspect}") if @sections.key?(key)
    @sections[key] = {}
    @sections[key][START_KEY] = as_of
  end

  def finish(key, as_of=Time.now.to_f)
    fail("Can't finish unknown section #{key.inspect}") unless @sections.key?(key)
    @sections[key] ||= {}
    fail("Attempt to (re-)finish immutable section #{key.inspect}") if @sections[key][FINISH_KEY]
    @sections[key][FINISH_KEY] = as_of
    @sections[key][TOOK_KEY] = as_of - @sections[key][START_KEY]
  end

  def took(key)
    if @sections.key?(key) && @sections[key].key?(TOOK_KEY)
      @sections[key][TOOK_KEY]
    else
      warn "Section #{key.inspect} has not finished, yet!"
    end
  end

  def to_s
    ordered_by_start.inspect
  end

  def section_keys
    @sections.keys
  end

  def finished_section_keys
    finished_sections.keys
  end

  def started_first
    key = ordered_by_start.first
    [key.first, key.last[START_KEY]]
  end

  def started_last
    key = ordered_by_start.last
    [key.first, key.last[START_KEY]]
  end

  def finished_first
    key = ordered_by_finish.first
    [key.first, key.last[FINISH_KEY]]
  end

  def finished_last
    key = ordered_by_finish.last
    [key.first, key.last[FINISH_KEY]]
  end

  private

  def finished_sections
    @sections.select { |s_key| @sections[s_key].key?(FINISH_KEY) }
  end

  def started_sections
    @sections.select { |s_key| @sections[s_key].key?(START_KEY) }
  end

  def ordered_by_finish
    finished_sections.sort { |l, r| l[1][FINISH_KEY] <=> r[1][FINISH_KEY] }
  end

  def ordered_by_start
    started_sections.sort { |l, r| l[1][START_KEY] <=> r[1][START_KEY] }
  end
end
