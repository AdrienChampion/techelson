open Base
open Common

module type SigStackRaw = sig
    module Theory : Theo.Sigs.SigTheory
    type t
    val fmt : formatter -> t -> unit

    val empty : t
    val is_empty : t -> bool

    val push : ?binding : Annot.Var.t option -> Dtyp.t -> Theory.value -> t -> unit
    val pop : t -> Theory.value * Dtyp.t
    val map_last : (Theory.value -> Dtyp.t -> Theory.value) -> t -> unit

    val swap : t -> unit
    val dip : t -> unit
    val dup : t -> unit
    val undip : t -> unit
end

module type SigStack = sig
    include SigStackRaw

    val pop_bool : t -> bool * Dtyp.t
    val pop_int : t -> Theory.Int.t * Dtyp.t
    val pop_nat : t -> Theory.Nat.t * Dtyp.t
    val pop_str : t -> Theory.Str.t * Dtyp.t
    val pop_key_hash : t -> Theory.KeyH.t * Dtyp.t
    val pop_tez : t -> Theory.Tez.t * Dtyp.t

    val pop_either : t -> (Theory.value, Theory.value) Theory.Either.t * Dtyp.t
    val pop_option : t -> Theory.value Theory.Option.t * Dtyp.t
    val pop_list : t -> Theory.value Theory.Lst.t * Dtyp.t
    val pop_operation_list : t -> Theory.operation list

    val pop_contract_params : Theory.Address.t -> t -> Theory.contract_params * Dtyp.t

    val some : ?alias : Dtyp.alias -> t -> unit
    val none : ?alias : Dtyp.alias -> Dtyp.t -> t -> unit

    val left : ?alias : Dtyp.alias -> Dtyp.t -> t -> unit
    val right : ?alias : Dtyp.alias -> Dtyp.t -> t -> unit

    val cons : t -> unit
    val nil : ?alias : Dtyp.alias -> Dtyp.t -> t -> unit

    val fmt : formatter -> t -> unit
end

module type SigContractEnv = sig
    module Theory : Theo.Sigs.SigTheory

    type t
    type live = private {
        address : Theory.Address.t ;
        contract : Contract.t ;
        mutable balance : Theory.Tez.t ;
        mutable storage : Theory.value ;
        params : Theory.contract_params ;
    }

    val empty : t
    val add : Contract.t -> t -> unit
    val get : string -> t -> Contract.t

    module Live : sig
        val create : Theory.contract_params -> Contract.t -> t -> unit
        val get : Theory.Address.t -> t -> live
        val fmt : formatter -> t -> unit
        val len : t -> int
    end
end


module type SigInterpreter = sig
    module Theory : Theo.Sigs.SigTheory
    module Stack : SigStack with module Theory = Theory
    module Address : Theo.Sigs.SigAddress with type t = Theory.Address.t
    module Contracts : SigContractEnv with module Theory = Theory

    module Src : sig
        type t =
        | Test of Testcase.t
        | Contract of Contract.t
        val fmt : formatter -> t -> unit
        val of_test : Testcase.t -> t
        val of_contract : Contract.t -> t
    end

    type t

    (* val empty : t
    val reset : src -> Contracts.t -> (Theory.value * Dtyp.t * Annot.Var.t option) list -> Mic.t list -> t -> unit *)

    val init : Src.t -> Contracts.t -> (Theory.value * Dtyp.t * Annot.Var.t option) list -> Mic.t list -> t
    val step : t -> bool
    val last_ins : t -> Mic.t option
    val next_ins : t -> Mic.t option
    val stack : t -> Stack.t
    val is_done : t -> bool
    val src : t -> Src.t
end

module type SigCxt = sig
    module Run : SigInterpreter
    module Theory = Run.Theory
    type t
end

module type SigStackOps = sig
    module Stack : SigStack

    val push : ?binding : Annot.Var.t option -> Dtyp.t -> Stack.Theory.value -> Stack.t -> unit
end