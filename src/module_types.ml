
module Random = struct
  (** Module types connected to random number generation. *)

  module type Rng = sig
    (** The core random generator signature. *)

    type g
    (** State type for this generator. *)
    val block_size : int
    (** Internally, this generator's {!generate} always produces [k * block_size] bytes. *)
    val generate : ?g:g -> int -> Cstruct.t
    (** [generate ~g n] produces [n] random bytes, using either the given or a
        default {!g}. *)
  end

  module type N = sig
    (** Typed random number extraction. *)

    type t
    (** The type of extracted values. *)
    type g
    (** Random generator. *)

    val gen : ?g:g -> t -> t
    (** [gen ~g n] picks a value in the interval [\[0, n - 1\]] uniformly at random. *)
    val gen_r : ?g:g -> t -> t -> t
    (** [gen_r ~g low high] picks a value from the interval [\[low, high - 1\]]
        uniformly at random. *)
    val gen_bits : ?g:g -> int -> t
    (** [gen_bits ~g n] picks a value with exactly [n] significant bits,
        uniformly at random. *)
  end

  module type Numeric = sig
    (** A full suite of numeric extractions. *)

    type g
    (** Random generator. *)

    val prime : ?g:g -> bits:int -> Z.t
    (** [prime ~g ~bits] generates a prime with [bits] significant bits, that
        is, from the interval [\[2^(bits - 1), 2^bits - 1\]]. *)
    val safe_prime : ?g:g -> bits:int -> Z.t * Z.t
    (** [safe_prime ~g ~bits] gives a prime pair [(g, p)] such that [p = 2g + 1]
        and [p] has [bits] significant bits. *)

    module Int   : N with type g = g and type t = int
    module Int32 : N with type g = g and type t = int32
    module Int64 : N with type g = g and type t = int64
    module Z     : N with type g = g and type t = Z.t
  end

end

module type Hash = sig
  type t

  val digest_size : int

  val init : unit -> t
  val feed : t    -> Cstruct.t -> unit
  val get  : t    -> Cstruct.t

  val digest  : Cstruct.t      -> Cstruct.t
  val digestv : Cstruct.t list -> Cstruct.t
end

module type Hash_MAC = sig
  include Hash
  val hmac : key:Cstruct.t -> Cstruct.t -> Cstruct.t
end


module Block = struct

  module type Cipher_raw = sig

    type ekey
    type dkey
    val e_of_secret : Cstruct.t -> ekey
    val d_of_secret : Cstruct.t -> dkey

    val key_sizes  : int array
    val block_size : int
    val encrypt_block : key:ekey -> Cstruct.t -> Cstruct.t -> unit
    val decrypt_block : key:dkey -> Cstruct.t -> Cstruct.t -> unit
  end

  module type Cipher_base = sig

    type key
    val of_secret : Cstruct.t -> key

    val key_sizes  : int array
    val block_size : int
    val encrypt : key:key -> Cstruct.t -> Cstruct.t
    val decrypt : key:key -> Cstruct.t -> Cstruct.t
  end

  module type ECB = sig

    type key
    val of_secret : Cstruct.t -> key

    val key_sizes  : int array
    val block_size : int
    val encrypt : key:key -> Cstruct.t -> Cstruct.t
    val decrypt : key:key -> Cstruct.t -> Cstruct.t
  end

  module type CBC = sig

    type key
    type result = { message : Cstruct.t ; iv : Cstruct.t }
    val of_secret : Cstruct.t -> key

    val key_sizes  : int array
    val block_size : int
    val encrypt : key:key -> iv:Cstruct.t -> Cstruct.t -> result
    val decrypt : key:key -> iv:Cstruct.t -> Cstruct.t -> result
  end

  module type CTR = sig

    type key
    val of_secret : Cstruct.t -> key

    val key_sizes  : int array
    val block_size : int
    val stream  : key:key -> ctr:Cstruct.t -> int -> Cstruct.t
    val encrypt : key:key -> ctr:Cstruct.t -> Cstruct.t -> Cstruct.t
    val decrypt : key:key -> ctr:Cstruct.t -> Cstruct.t -> Cstruct.t
  end

  module type GCM = sig

    type key
    type result = { message : Cstruct.t ; tag : Cstruct.t }
    val of_secret : Cstruct.t -> key

    val key_sizes  : int array
    val block_size : int
    val encrypt : key:key -> iv:Cstruct.t -> ?adata:Cstruct.t -> Cstruct.t -> result
    val decrypt : key:key -> iv:Cstruct.t -> ?adata:Cstruct.t -> Cstruct.t -> result
  end

  module type CCM = sig

    type key
    val of_secret : maclen:int -> Cstruct.t -> key

    val key_sizes  : int array
    val mac_sizes  : int array
    val block_size : int
    val encrypt : key:key -> nonce:Cstruct.t -> ?adata:Cstruct.t -> Cstruct.t -> Cstruct.t
    val decrypt : key:key -> nonce:Cstruct.t -> ?adata:Cstruct.t -> Cstruct.t -> Cstruct.t option
  end

  module type Counter = sig
    val increment : Cstruct.t -> unit
  end

end

module type Stream_cipher = sig
  type key
  type result = { message : Cstruct.t ; key : key }
  val of_secret : Cstruct.t -> key
  val encrypt : key:key -> Cstruct.t -> result
  val decrypt : key:key -> Cstruct.t -> result
end

