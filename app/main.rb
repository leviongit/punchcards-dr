require_relative "utils"
require_relative "vm"

class Game
  attr_accessor :args

  @@kbithash = {
    s: 0x80,
    d: 0x40,
    f: 0x20,
    g: 0x10,
    h: 0x08,
    j: 0x04,
    k: 0x02,
    l: 0x01
  }.freeze

  @@kbitkeys = @@kbithash.keys.freeze

  def input
    @keys = @inputs.keyboard.keys
    if @keys.held.empty?
      # translate it good
      @chrlst << @keyset.filter_map(&@@kbithash).sum unless @keyset.empty?
      @keyset.clear
    else
      @keyset.replace(@keyset.concat(@keys.held) & @@kbitkeys)
    end
    1
  end

  def tick
    @keyset ||= []
    @chrlst ||= []
    @inputs = @args.inputs
    @outputs = @args.outputs
    input
    render
  end

  def render
    @outputs.labels << [
      "how to play:",
      "  punch holes in accordance to the ascii codes of the characters",
      "  to fix a mistake you have to punch out <del>",
      "  gl",
      nil,
      "#{@keyset} :: #{@chrlst.map(&:chr).join}"
    ].map_with_index { |t, i|
      {
        x: 10,
        y: 480,
        text: t,
        anchor_x: 0,
        anchor_y: 1 + i
      }
    }

    @dc ||= { r: 0x23, g: 0x23, b: 0x32 }
    @bc ||= { r: 0xaa, g: 0xaa, b: 0xbb }

    @outputs.primitives.concat(
      (@chrlst + [0]).flat_map.with_index { |c, i|
        ord = c
        w = 10
        h = 10
        8.map { |ii|
          hh = {
            x: (i + 1) * w,
            y: (h / 4) + ii * h,
            w: w,
            h: h
          }
          [
            { **((ord & (1 << ii)).zero? ? @dc : @bc), path: :pixel },
            { **@dc, primitive_marker: :border }
          ].map {
            { **_1, **hh }
          }
        }.flatten!
      }
    )
  end
end

def tick(args)
  $game ||= Game.new
  $game.args = args
  $game.tick
end

def reset(_args)
  $game = nil
end
