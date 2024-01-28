#!/usr/bin/env ruby

module  IMethyl

  class Stats

    LINES_PER_OUTFILE = 1000000
    LINES_PER_PROGRESS = 100000

    def initialize
      @stats_file = nil
      @dataset = nil
      @f_out_prefix = "out"
      @f_out_dir = "./"
      @f_out_name = ""
      @rdf_format = :turtle
      @output = nil
      @fout = nil
    end
    attr_accessor :stats_file, :dataset, :f_out_prefix, :output,
                  :f_out_dir, :rdf_out_name, :rdf_format, :fout

    def to_rdf
      if CHROMOSOME
        begin
          chr_num = 1
          chr_prev = 1
          local_cnt = 1
          open(set_output(chr_num))
          puts_prefix
          $stderr.print "#{@f_out_name} " if VERBOSE
          File.open(@stats_file) do |file|
            file.gets
            file.each.with_index(1) do |line, i|
              ary = line.chomp.split("\t")
              chr_num = ary[0].to_i
              $stderr.print "." if local_cnt%LINES_PER_PROGRESS == 0 && VERBOSE
              if chr_num != chr_prev
                @fout.close
                set_output(chr_num)
                local_cnt = 1
                puts_prefix
                puts_turtle(ary)
                $stderr.print "\n#{@f_out_name} " if VERBOSE
              else
                puts_turtle(ary)
                local_cnt += 1
              end
              chr_prev = chr_num
            end
          end
          @fout.close
          $stderr.print "\n" if VERBOSE
        end
      else
        begin
          file_count = 1
          open(set_output(file_count))
          puts_prefix
          $stderr.print "#{@f_out_name} " if VERBOSE
          File.open(@stats_file) do |file|
            file.gets
            file.each.with_index(1) do |line, i|
              ary = line.chomp.split("\t")
              $stderr.print "." if i%LINES_PER_PROGRESS == 0 && VERBOSE
              if  i%LINES_PER_OUTFILE == 0
                file_count += 1
                puts_turtle(ary)
                @fout.close
                set_output(file_count)
                puts_prefix
                $stderr.print "\n#{@f_out_name} " if VERBOSE
              else
                puts_turtle(ary)
              end
            end
          end
        end
        @fout.close
        $stderr.print "\n" if VERBOSE
      end
    end

    def puts_prefix
      @fout.puts <<-PREFIX
@prefix imo: <http://purl.jp/bio/10/imethyl/ontology#> .
@prefix imd: <http://purl.jp/bio/10/imethyl/dataset#> .
@prefix ims: <http://purl.jp/bio/10/imethyl/sample#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix dc: <http://purl.org/dc/terms/> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix obo: <http://purl.obolibrary.org/obo/> .
@prefix sio: <http://semanticscience.org/resource/> .
@prefix taxonomy: <http://identifiers.org/taxonomy/> .
@prefix pubmed: <http://rdf.ncbi.nlm.nih.gov/pubmed/> .
@prefix faldo: <http://biohackathon.org/resource/faldo#> .
@prefix hg19: <http://rdf.ebi.ac.uk/resource/ensembl/90/homo_sapiens/GRCh38/> .
@prefix hco: <http://identifiers.org/hco/> .

      PREFIX
    end

    def puts_turtle(ary)
      @fout.puts <<-TURTLE
 [
     a imo:CDMVStat;
     faldo:location [
       a faldo:ExactPosition;
       faldo:position #{ary[1]};
       faldo:reference hg19:#{ary[0]};
       faldo:reference hco:#{ary[0]}\/GRCh38
     ];
     imo:sample imd:#{@dataset};
     sio:SIO_000216 [
       sio:SIO_000221 imo:RI;
       sio:SIO_000300 #{ary[3]}
     ],  [
       sio:SIO_000221 sio:SIO_001110;
       sio:SIO_000300 #{ary[2]}
     ],  [
       sio:SIO_000221 sio:SIO_001109;
       sio:SIO_000300 #{ary[4]}
     ],  [
       sio:SIO_000221 sio:SIO_000770;
       sio:SIO_000300 #{ary[5]}
     ]
 ] .
 
      TURTLE
    end

    def set_output(file_count)
      num = "%#02d" % file_count 
      @f_out_name = @f_out_prefix + "-#{num}" + '.ttl'
      @output = @f_out_dir + '/' + @f_out_name
      @fout = open(@output, "w")
    end
  end

  class Dataset

    def initialize
      @stats_file = nil
      @dataset = nil
      @f_out_prefix = "out"
      @f_out_dir = "./"
      @f_out_name = ""
      @rdf_format = :turtle
      @output = nil
      @fout = nil
    end
    attr_accessor :stats_file, :dataset, :f_out_prefix, :output,
                  :f_out_dir, :rdf_out_name, :rdf_format, :fout

    def to_rdf
      @fout = open(@f_out_dir + "/" + @f_out_prefix + ".ttl", "w")
      begin
        puts_prefix
#        $stderr.print "#{@f_out_name} " if VERBOSE
        statements = []
        File.open(@dataset) do |file|
          file.gets
          file.each_line do |line|
            ary = line.chomp.split("\t")
            if /^\S+/ =~ ary[0]
              case ary[2]
              when /Dataset/
                @fout.print "#{statements.join(" ;\n")}" unless statements == []
                @fout.print ". \n\n"                     unless statements == []
                statements = []
                @fout.print "imd:#{ary[0]} a imo:Dataset ;\n"
              when /Sample/
                @fout.print "#{statements.join(" ;\n")}"
                @fout.print ". \n\n"
                statements = []
                @fout.print "ims:#{ary[0]} a imo:Sample ;\n"
              when /Protocol/
                @fout.print "#{statements.join(" ;\n")}"
                @fout.print ". \n\n"
                statements = []
                @fout.print "imp:#{ary[0]} a imo:Protocol ;\n"
              else
              end
            elsif /^$/ =~ ary[0]
              case ary[1]
              when /description/, /purpose/
                statements << "    dc:description \"#{ary[2]}\"@en"
              when /protocol/, /sample/
                statements << "    imo:#{ary[1].to_snake} #{ary[2]}"
              when /citation/
                statements << "    dc:references pubmed:29263827"
              when /ProtocolName/
                statements << "    rdfs:label \"#{ary[2]}\""
              when /ReadLength/, /AverageDepth/
                statements << "    imo:#{ary[1].to_snake} #{ary[2]}"
              else
                statements << "    imo:#{ary[1].to_snake} \"#{ary[2]}\""
              end
            end
          end
        end
        @fout.print "#{statements.join(" ;\n")}"
        @fout.print ". \n\n"
      end
    end

    def puts_prefix
      @fout.puts <<-PREFIX
@prefix imo: <http://purl.jp/bio/10/imethyl/ontology#> .
@prefix imd: <http://purl.jp/bio/10/imethyl/dataset#> .
@prefix ims: <http://purl.jp/bio/10/imethyl/sample#> .
@prefix imp: <http://purl.jp/bio/10/imethyl/protocol#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix dc: <http://purl.org/dc/terms/> .
@prefix skos: <http://www.w3.org/2004/02/skos/core#> .
@prefix obo: <http://purl.obolibrary.org/obo/> .
@prefix sio: <http://semanticscience.org/resource/> .
@prefix taxonomy: <http://identifiers.org/taxonomy/> .
@prefix pubmed: <http://rdf.ncbi.nlm.nih.gov/pubmed/> .

      PREFIX
    end

  end
  
end

class String
  def to_snake()
    self
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr("-", "_")
      .downcase
  end
end

def help
  puts <<HELP

Usage: imethyl2rdf [options]
    -v              verbose mode 
    -t              split output by chromosome (optional)
    -c COMMNAD      stats || dataset (required)
    -i FILENAME     input file (required)
    -s DATASET      dataset name (required when -c stats)
    -o FILEPREFIX   prefix of the output file(s) (default: 'out')
    -d DIRNAME      output directory (default: '.')

Example:
    > imethyl2rdf -v -t -c stats -i example.stat.txt -s Mono -o out -d ./out/ 
    > imethyl2rdf -v -c dataset -i iMethyl-RDF-Dataset-Description.tsv -o  -d ./out/ 

HELP
end

if $0 == __FILE__ then

require 'optparse'

params = Hash[ARGV.getopts('c:vti:s:o:d:', 'help').map {|k,v| [k.to_sym, v]}]
VERBOSE = params[:v]
CHROMOSOME = params[:t]
if params[:h] || params[:help]
  help
elsif params[:i] && params[:s] && params[:c] == "stats"
  im = IMethyl::Stats.new
  im.stats_file   = params[:i]
  im.dataset      = params[:s]
  im.f_out_prefix = params[:o]         if params[:o]
  im.f_out_dir    = params[:d]         if params[:d]
  im.to_rdf
elsif params[:c] == "dataset"
  im = IMethyl::Dataset.new
  im.dataset      = params[:i]
  im.f_out_prefix = params[:o]         if params[:o]
  im.f_out_dir    = params[:d]         if params[:d]
  im.to_rdf
else
  $stderr.puts "ERROR: input file missing."
end

end 

