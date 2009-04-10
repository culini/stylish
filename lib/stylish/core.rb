module Stylish
  
  # Regular expressions matching a percentage, and matching only a percentage.
  PCT        = /-?(0\.)?\d+%/
  PERCENTAGE = /^#{PCT}$/
  
  # A list of all valid HTML5 elements. Used primarily in the stylesheet
  # generation DSL as method names.
  HTML_ELEMENTS = [:html, :head, :title, :base, :link, :meta, :style, :script,
                   :noscript, :eventsource, :body, :section, :nav, :article,
                   :aside, :header, :footer, :address, :p, :hr, :br, :pre,
                   :dialog, :blockquote, :ol, :ul, :li, :dl, :dt, :dd, :a, :q,
                   :cite, :em, :strong, :small, :mark, :dfn, :abbr, :time,
                   :progress, :meter, :code, :var, :samp, :kbd, :sub, :sup,
                   :span, :i, :b, :bdo, :ruby, :rt, :rp, :ins, :del, :figure,
                   :img, :iframe, :embed, :object, :param, :video, :audio,
                   :source, :canvas, :map, :area, :table, :caption, :colgroup,
                   :col, :tbody, :thead, :tfoot, :tr, :td, :th, :form,
                   :fieldset, :label, :input, :button, :select, :datalist,
                   :optgroup, :option, :textarea, :output, :details, :datagrid,
                   :command, :bb, :menu, :legend, :div]
  
  class Rule
    include Formattable, Tree::Leaf
    
    attr_reader :selectors, :declarations
    
    def initialize(selectors, *declarations)
      accept_format(/^\s*%s\s*\{\s*%s\s*\}\s*$/m, "%s {%s}")
      
      @selectors = selectors.inject(Selectors.new) do |ss, s|
        ss << s
      end
      
      @declarations = declarations.inject(Declarations.new) do |ds, d|
        ds << d
      end
    end
    
    # Serialise the rule to valid CSS code.
    def to_s(scope = "")
      selectors = @selectors.map do |selector|
        (scope.empty? ? "" : scope + " ") + selector.to_s
      end
      
      sprintf(@format, selectors.join, @declarations.join)
    end
  end
  
  class Comment
    attr_reader :header, :lines, :metadata
    
    def initialize(*args)
      @lines, @metadata = [], {}
      
      args.each do |arg|
        if arg.is_a? String
          unless @header.nil?
            @lines << arg
          else
            @header = arg
          end
        elsif arg.is_a? Hash
          @metadata.merge!(arg)
        end
      end
      
      def to_s
        if @lines.empty? && @metadata.empty?
          sprintf("/**\n * %s\n */", @header)
        else
          header = sprintf(" * %s", @header) unless @header.nil?
          lines = @lines.map {|l| ' * ' + l }.join("\n") unless @lines.empty?
          metadata = @metadata.to_a.map {|name, value|
            sprintf(" * @%s %s", name.to_s, value.to_s)
          }.join("\n") unless @metadata.empty?
          
          sprintf("/**\n%s\n */", [
            header || nil,
            lines || nil,
            metadata || nil
          ].compact.join("\n *\n"))
        end
      end
    end
  end
  
  class Selector
    
    def initialize(str)
      @selector = str.to_s
    end
    
    def to_s
      @selector
    end
  end
  
  class Selectors < Array
    include Formattable
    
    def initialize(*args)
      accept_format(/^\s*,\s*$/m, ", ")
      super
    end
    
    def join
      super(@format)
    end
    
    def to_s
      self.join
    end
  end
  
  class Declaration
    include Formattable
    
    attr_accessor :value
        
    def initialize(prop, val = nil)
      accept_format(/^\s*%s\s*:\s*%s;\s*$/m, "%s:%s;")
      self.value = val
      self.property = prop
    end
    
    def property
      @property
    end
    
    def property=(prop)
      @property = prop.to_s
    end
    
    def value=(val)
      @value = val
    end
    
    def to_s
      sprintf(@format, @property, @value)
    end
  end
  
  
  # Declarations subclasses Array so that whenever #join is called, the
  # instance's format attribute will be used as the join string, rather than
  # the empty string.
  class Declarations < Array
    include Formattable
    
    # The allowed format is any string consisting only of whitespace
    # characters, including newline. The default format string is a single
    # space, which is probably the most common choice in hand-written CSS.
    def initialize(*args)
      accept_format(/^\s*$/m, " ")
      super
    end
    
    # The format attribute is always used as the separator when joining the
    # elements of a Declarations object.
    def join
      super(@format)
    end
    
    # Returns a string by converting each element to a string, separated by the
    # format attribute. Assuming that its contents are indeed Declaration
    # objects, this will invoke their own #to_s method and generating correct
    # CSS code.
    def to_s
      self.join
    end
  end
  
  class Background < Declaration
    attr_reader :color,
                :image,
                :repeat,
                :position,
                :attachment,
                :compressed
    
    PROPERTIES = [
      [:color,      "background-color"],
      [:image,      "background-image"],
      [:repeat,     "background-repeat"],
      [:position,   "background-position"],
      [:attachment, "background-attachment"],
      [:compressed]]
    
    REPEAT_VALUES        = ["repeat", "repeat-x", "repeat-y", "no-repeat"]
    ATTACHMENT_VALUES    = ["scroll", "fixed", "inherit"]
    HORIZONTAL_POSITIONS = ["left", "center", "right"]
    VERTICAL_POSITIONS   = ["top", "center", "bottom"]
    
    # Create a new Background object
    def initialize(options)
      accept_format(/^\s*%s\s*:\s*%s;\s*$/m, "%s:%s;")
      self.value = options
    end
    
    # Input validation for colours is handled by the Color class, which will
    # raise an ArgumentError if the argument is an invalid colour value.
    def color=(val)
      @color = Color.new(val)
    end
    
    # Set the background image.
    def image=(path)
      @image = path if path.is_a?(String) || path.is_a?(File)
    end
    
    # Set the background repeat.
    def repeat=(val)
      @repeat = val if REPEAT_VALUES.include?(val)
    end
    
    # Only position keywords are currently handled, not percentages or lengths.
    def position=(val)
      xpos, ypos = val.split(/\s+/) << "center"
      if HORIZONTAL_POSITIONS.include?(xpos) && VERTICAL_POSITIONS.include?(ypos)
        @position = [xpos, ypos]
      end
    end
    
    # The background-attachment property takes a limited range of values, so
    # only a value within that range will be accepted.
    def attachment=(val)
      @attachment = val if ATTACHMENT_VALUES.include?(val)
    end
    
    # Set this to true to generate a compressed declaration, e.g.
    #
    #     background:#ccc url('bg.png') no-repeat 0 0;
    #
    # As opposed to the uncompressed version:
    #
    #     background-color:#ccc; background-image:url('bg.png');
    #     background-repeat:no-repeat; background-position:0 0;
    #
    def compressed=(val)
      @compressed = val == true || nil
    end
    
    # Override Declaration#property, since it's not compatible with the
    # internals of this class.
    def property
      PROPERTIES.reject {|n, p| p.nil? }.map {|n, p|
        value = self.send(n)
        p.to_s unless value.nil?
      }.compact
    end
    
    # Override Declaration#property=, since it's not compatible with the
    # internals of this class.
    def property=(val)
      raise NoMethodError, "property= is not defined for Background."
    end
    
    # Override Declaration#value, since it's not compatible with the internals
    # of this class.
    def value(name_and_value = false)
      PROPERTIES.reject {|n, p| p.nil? }.map {|n, p|
        value = self.send(n)
        next if value.nil?
        name_and_value ? [p.to_s, value] : value
      }.compact
    end
    
    # Override Declaration#value=, since it's not compatible with the internals
    # of this class.
    def value=(options)
      unless options.is_a? Hash
        raise ArgumentError, "Argument must be a hash of background properties"
      end
      
      PROPERTIES.each do |name, property|
        self.send(:"#{name.to_s}=", options[name]) if options[name]
      end
    end
    
    # Generate a string representation of a Background instance.
    #
    # There are two kinds of representation, each of which have slightly
    # different CSS semantics. If compressed is set to true, this method will
    # produce a shorthand CSS declaration such as the following:
    #
    #     background: #fff url('bg.png') no-repeat 50% 0;
    #
    # Otherwise it will produce an unordered list of individual background
    # declarations.
    def to_s
      if @compressed
        "background:#{self.value(true).map {|p, v| v }.compact.join(" ")};"
      else
        self.value(true).map {|p, v| sprintf(@format, p, v.to_s) }.join(" ")
      end
    end
  end
  
end
