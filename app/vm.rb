class PcVM
  class << self
    def op(name, &blk)
      @ops ||= [:op_unimp] * 256
      @opc ||= 0
      raise if @opc == 256

      name = :"op_#{name}"
      @ops[@opc] = name
      @opc += 1

      arity = blk.arity
      p arity
      assert! { arity >= 0 }

      if arity == 1
        define_method(name) {
          @ri += 1
          args, = take_args(arity)
          self.instance_exec(args, &blk)
        }
      elsif arity > 1
        define_method(name) {
          @ri += 1
          args = take_args(arity)
          self.instance_exec(*args, &blk)
        }
      else
        define_method(name) {
          @ri += 1
          self.instance_exec(&blk)
        }
      end
    end

    attr_accessor :ops
  end

  def initialize(iseq = [])
    assert! { Array === iseq }

    @iseq = iseq

    @ra = 0
    @rb = 0
    @rc = 0
    @rd = 0
    @rx = 0
    @ry = 0
    @rz = 0
    @ri = 0
    @mem = 0
  end

  @@reglt = %i[
    @ra
    @rb
    @rc
    @rd
    @rx
    @ry
    @rz
    @mem
  ]

  def take_args(arity)
    vs = @iseq[@ri, arity]
    @ri += arity - 1
    vs
  end

  op(:nop) {
    @ri += 1
  }

  op(:add) { |rs|
    rd = @@reglt[rs & 0x7]
    rs = @@reglt[(rs >> 3) & 0x7]

    dv = instance_variable_get(rd)
    sv = instance_variable_get(rs)
    v = (dv + sv) & 0xff
    instance_variable_set(rd, v)
  }

  op(:sub) { |rs|
    rd = @@reglt[rs & 0x7]
    rs = @@reglt[(rs >> 3) & 0x7]

    dv = instance_variable_get(rd)
    sv = instance_variable_get(rs)
    v = (dv - sv) & 0xff
    instance_variable_set(rd, v)
  }

  op(:loadi) { |reg, data|
    rd = @@reglt[reg & 0x7]

    instance_variable_set(rd, data)
  }

  def op_notimpl
    raise "unknown op at #{@ri}"
  end

  def tick
    self.send(self.class.ops[@iseq[@ri]])
    @ri += 1
  end
end
