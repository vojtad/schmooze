require 'json'

module Schmooze
  class ProcessorGenerator
    class << self
      def generate(imports, methods, es6: false)
%{try {
#{imports.map {|import| generate_import(import, es6: es6)}.join}} catch (e) {
  process.stdout.write(JSON.stringify(['err', e.toString()]));
  process.stdout.write("\\n");
  process.exit(1);
}

process.stdout.write("[\\"ok\\"]\\n");
var __methods__ = {};
#{methods.map{ |method| generate_method(method[:name], method[:code]) }.join}
function __handle_error__(error) {
  if (error instanceof Error) {
    process.stdout.write(JSON.stringify(['err', error.toString().replace(new RegExp('^' + error.name + ': '), ''), error.name, error.stack]));
  } else {
    process.stdout.write(JSON.stringify(['err', error.toString()]));
  }
  process.stdout.write("\\n");
}
#{generate_readline_import(es6: es6)}.createInterface({
  input: process.stdin,
  terminal: false,
}).on('line', function(line) {
  var input = JSON.parse(line);
  try {
    Promise.resolve(__methods__[input[0]].apply(null, input[1])
    ).then(function (result) {
      process.stdout.write(JSON.stringify(['ok', result]));
      process.stdout.write("\\n");
    }).catch(__handle_error__);
  } catch(error) {
    __handle_error__(error);
  }
});
}
      end

      def generate_method(name, code)
        "__methods__[#{name.to_json}] = (#{code});\n"
      end

      def generate_import(import, es6:)
        if import[:package].start_with?('.') # if it local script else package
          _, _, package, mid, path = import[:package].partition('.')
          package = ".#{package}"
        else
          package, mid, path = import[:package].partition('.')
        end

        "  var #{import[:identifier]} = #{import(package, es6: es6)}#{mid}#{path};\n"
      end

      def generate_readline_import(es6:)
        import('readline', es6: es6)
      end

      def import(package, es6:)
        if es6
          "(await import(#{package.to_json}))"
        else
          "require(#{package.to_json})"
        end
      end
    end
  end
end
