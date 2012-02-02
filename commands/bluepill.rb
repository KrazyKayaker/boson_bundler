module Bluepill
    def self.after_included
        require 'boson_bundler'
        BosonBundler.setup 'bluepill'
    end

    # launches a bluepill process
    def bluepill(*args)

        require 'pillbox'

        bluepill_base = PillBox.bluepill_base
        bluepill_log = File.join(BosonBundler.bundle_path('bluepill'), 'logs')
        #BosonBundler.bin_path 'bluepill', 'bluepill', %W( -c #{bluepill_base} -l #{bluepill_log}) +  args + %w( --no-privileged )
        $0 = File.absolute_path $0
        BosonBundler.bin_path 'bluepill', 'bluepill', %W( -c #{bluepill_base} -l #{bluepill_log} --no-privileged) +  args 
    end

    # a proxy to bluepill
    def bluepill_cli(*args)
        BosonBundler.bin_path 'bluepill', 'bluepill', args
    end
end
