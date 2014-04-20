require 'date'

class FuzzyDate

  # *Note*: This is only for single dates - not ranges.
  #
  # Possible incoming date formats:
  # * YYYY-MM-DD  -  starts with 3 or 4 digit year, and month and day may be 1 or 2 digits
  # * YYYY-MM     -  3 or 4 digit year, then 1 or 2 digit month
  # * YYYY        -  3 or 4 digit year
  # * MM-DD-YYYY  -  1 or 2 digit month, then 1 or 2 digit day, then 1 to 4 digit year
  # * DD-MM-YYYY  -  1 or 2 digit day, then 1 or 2 digit month, then 1 to 4 digit year if euro is true
  # * MM-YYYY     -  1 or 2 digit month, then 1 to 4 digit year
  # * DD-MMM      -  1 or 2 digit day, then month name or abbreviation
  # * DD-MMM-YYYY -  1 or 2 digit day, then month name or abbreviation, then 1 to 4 digit year
  # * MMM-YYYY    -  month name or abbreviation, then 1 to 4 digit year
  # * MMM-DD-YYYY -  month name or abbreviation, then 1 or 2 digit day, then 1 to 4 digit year
  #
  # Notes:
  # - Commas are optional.
  # - Delimiters can be most anything non-alphanumeric.
  # - All dates may be suffixed with the era (AD, BC, CE, BCE). AD is assumed.
  # - Dates may be prefixed by circa words (Circa, About, Abt).

  private

  def analyze( date, euro )

    date = clean_parameter date

    @date_parts[ :original ] = date

    date = massage date
    @date_parts[ :fixed ] = date

    year, month, day = nil

    if date =~ @date_patterns[ :yyyy ]
      year  = stringify $1

    elsif date =~ @date_patterns[ :yyyy_mm_dd_and_yyyy_mm ]
      year  = stringify $1
      month = stringify $2 unless $2.nil?
      day   = stringify $3 unless $3.nil?

    elsif date =~ @date_patterns[ :dd_mm_yyyy ] and euro
      day   = stringify $1
      month = stringify $2
      year  = stringify $3

    elsif date =~ @date_patterns[ :mm_dd_yyyy ]
      month = stringify $1
      day   = stringify $2
      year  = stringify $3

    elsif date =~ @date_patterns[ :mm_yyyy ]
      month = stringify $1
      year  = stringify $2

    elsif date =~ @date_patterns[ :dd_mmm_yyyy_and_dd_mmm ]
      month_text  = $2.to_s.capitalize
      month       = stringify @month_names.key( @month_abbreviations[ month_text ] )
      day         = stringify $1
      year        = stringify $3 unless $3.nil?

    elsif date =~ @date_patterns[ :mmm_dd_yyyy ]
      month_text  = $1.to_s.capitalize
      month       = stringify @month_names.key( @month_abbreviations[ month_text ] )
      day         = stringify $2
      year        = stringify $3 unless $3.nil?

    elsif date =~ @date_patterns[ :mmm_yyyy_and_mmm ]
      month_text  = $1.to_s.capitalize
      month       = stringify @month_names.key( @month_abbreviations[ month_text ] )
      year        = stringify $2 unless $2.nil?

    else
      raise ArgumentError.new( 'Cannot parse date.' )
    end

    @date_parts[ :year   ] = year  ? year.to_i   : nil
    @date_parts[ :month  ] = month ? month.to_i  : nil
    @date_parts[ :day    ] = day   ? day.to_i    : nil

    #- Some error checking at this point
    if month.to_i > 13
      raise ArgumentError.new( 'Month cannot be greater than 12.' )
    elsif month and day and day.to_i > @days_in_month[ month.to_i ]
      unless month.to_i == 2 and year and Date.parse( '1/1/' + year ).leap? and day.to_i == 29
        raise ArgumentError.new( 'Too many days in this month.' )
      end
    elsif month and month.to_i < 1
      raise ArgumentError.new( 'Month cannot be less than 1.' )
    elsif day and day.to_i < 1
      raise ArgumentError.new( 'Day cannot be less than 1.' )
    end

    month_name = @month_names[ month.to_i ]
    @date_parts[ :month_name ] = month_name

    # ----------------------------------------------------------------------

    show_era = ' ' + @date_parts[ :era ]
    show_circa = @date_parts[ :circa ] == true ? 'About ' : ''

    if year and month and day
      @date_parts[ :short  ] = show_circa + month + '/' + day + '/' + year + show_era
      @date_parts[ :long   ] = show_circa + month_name + ' ' + day + ', ' + year + show_era
      modified_long = show_circa + month_name + ' ' + day + ', ' + year.rjust( 4, "0" ) + show_era
      @date_parts[ :full   ] = show_circa + Date.parse( modified_long ).strftime( '%A,' ) + Date.parse( day + ' ' + month_name + ' ' + year.rjust( 4, "0" ) ).strftime( ' %B %-1d, %Y' ) + show_era
    elsif year and month
      @date_parts[ :short  ] = show_circa + month + '/' + year + show_era
      @date_parts[ :long   ] = show_circa + month_name + ', ' + year + show_era
      @date_parts[ :full   ] = @date_parts[ :long ]
    elsif month and day
      month_text = @month_abbreviations.key(month_text) || month_text
      @date_parts[ :short  ] = show_circa + day + '-' + month_text
      @date_parts[ :long   ] = show_circa + day + ' ' + month_name
      @date_parts[ :full   ] = @date_parts[ :long ]
    elsif year
      @date_parts[ :short  ] = show_circa + year + show_era
      @date_parts[ :long   ] = @date_parts[ :short  ]
      @date_parts[ :full   ] = @date_parts[ :long   ]
    end

    @date_parts

  end

  def clean_parameter( date )
    date.to_s.strip if date.respond_to? :to_s
  end

  def massage( date )

    date_in_parts = []

    date_separator = Regexp.new DATE_SEPARATOR, true

    #- Split the string

    date_in_parts = date.split date_separator
    date_in_parts.delete_if { |d| d.to_s.empty? }
    if date_in_parts.first.match Regexp.new( @circa_words.join( '|' ), true )
      @date_parts[ :circa ] = true
      date_in_parts.shift
    end
    if date_in_parts.last.match Regexp.new( @era_words.join( '|' ), true )
      @date_parts[ :era ] = date_in_parts.pop.upcase.strip
    end

    date_in_parts.join '-'
  end

  def stringify( capture )
    capture.to_i.to_s
  end

end