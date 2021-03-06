class Query
  include XMLResultsParser

# The main object dealt with in tests. Queries require:
#
# A Request object - these can be passed in as an argument when
# the query is created, or by default a blank request is created.
# Request objects format the actual request that goes to Solr,
# and are accessed by @request.
#
# A parser - in this case the XMLResultsParser mixin.
#
# An output object. This can be passed in when the query is created,
# by default it is ToTerminal. The output object formats results.
# The outputter is accessed by @output.

  # Query.new :output => CSV, :request => BoostEverything
  # defaults to the Request class and ToTerminal
  def initialize opts ={}

    @parsed_results = nil

    defaults = {
      :output => ToTerminal.new,
      :request => Request.new,
			:explain => nil
    }

    @output = opts[:output] || defaults[:output]
    @request = opts[:request] || defaults[:request]
    @explain = opts[:explain] || defaults[:explain]

		if @explain
			@request.explain = true
		end
  end

  # A quick way of firing off a query: query << 'tki things'
  # Sets the search term(s), and gets the results, printing them
  # atomatically.
  def <<(string)
    self.term(string)

    self.results :print => true
  end
  
  def verbose(string)
    self.term(string)

    self.results :verbose => true
  end

  # A setter for the search term.
  def term(string)
    @request.q = string
  end
  
  
  def q
    @request.q
  end
  

  # The main method for Queries - automatic printing to
  # output is optional, off by default.
  #
  # Calls get_results, or returns the @results if already populated.
  def results opts ={}
    defaults = { :print => nil, :verbose => nil }

    print   = opts[:print] || defaults[:print]
    verbose = opts[:verbose] || defaults[:verbose]

    get_results if @parsed_results == nil
    
    if print
      @output << @request.full
      @output << @parsed_results
    end
    
    if verbose
      puts @raw_results
    end

    @parsed_results

  end

  # Runs results with print set.
  def print
    results :print => true
  end

  # A reader method of the entire request string
  # inside the request object.
  def request
    @request.full
  end


  private

  # Creates nokogiri object and sends it to the parse method
  # in the XMLResultsParser mixin, before returning the parsed
  # results.
  #
  # Parsed in this context means 'useful elements extracted and
  # put in to a ruby datastructure'...
  def get_results
    begin
      results = Nokogiri::XML(open(URI.encode(@request.full)))
    rescue SystemCallError, EOFError
      retry
    end
    # puts results
    parse results, :query => @request.q
  end


end

