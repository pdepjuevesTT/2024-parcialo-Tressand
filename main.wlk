class Persona {
    var property formasDePago = []
    var property formaDePagoPreferida = null
    const efectivo = new Debito(dinero = 0) //El efectivo tiene el mismo comportamiento que el débito pero es variable privada
    const dineroInicial

    method initialize() {
        formasDePago.add(efectivo)
        efectivo.sumarADinero(dineroInicial)
        formaDePagoPreferida = efectivo
    }

    const property inventario = []

    method comprar(obj) {
        if(!inventario.contains(obj))
        {
            self.formaDePagoPreferida().pagar(obj, self)
        }
    }

    var salario
    method aumentoDeSalario(valor) {if (valor >= 0) salario += valor}

    var property sueldoRestante = 0
    method restarASueldo(cant) { sueldoRestante -= cant }

    method cobrarSueldo() {
        sueldoRestante = salario
        formasDePago.forEach({ formaDePago => 
        formaDePago.cuandoPasaMes(self)
        })
        efectivo.sumarADinero(sueldoRestante)
        sueldoRestante = 0
    }

    method totalImpago() {
        var total = 0
        formasDePago.forEach({formaDePago => total += formaDePago.totalImpago()})
        return total
    }

    method sumaDeDeuda() {
        var total = 0
        formasDePago.forEach({formaDePago => total += formaDePago.sumaDeDeuda()})
        return total
    }
}

class Debito {
    var property dinero
    method sumarADinero(cant) {dinero += cant}
    
    method dineroSuficiente(cant) = dinero > cant
    
    method pagar(obj, propietario) {
        if (self.dineroSuficiente(obj.precio())) {
            dinero -= obj.precio()
            propietario.inventario().add(obj)
        }
    }

    method cuandoPasaMes(origen) {} // No hacer nada

    method sumaDeDeuda() = 0
    method totalImpago() = 0
}

class Credito {
    const bancoEmisor
    const listaDeDeudas = []

    method pagar(obj, propietario) {
        if (self.sumaDeDeuda() + obj.precio() < bancoEmisor.maximo()) {
            listaDeDeudas.add(new Deuda(monto = ((obj.precio() * bancos.tasaInteres()) / bancoEmisor.cuotas()), cantCuotas = bancoEmisor.cuotas()))
            propietario.inventario().add(obj)
        }
    }

    method sumaDeDeuda() {
        var total = 0
        listaDeDeudas.forEach({elem => total += elem.total()})
        return total
    }
    method totalImpago() {
        var total = 0
        listaDeDeudas.forEach({deuda => total += deuda.totalImpago()})
        return total
    }

    method cuandoPasaMes(propietario) {
        listaDeDeudas.forEach({ deuda =>
            (deuda.cantVencidas()).times({ i => self.intentarPagarDeuda(propietario, deuda)})
            if (!self.intentarPagarDeuda(propietario, deuda)) { deuda.vencerCuota() }
        })
    }

    method intentarPagarDeuda(persona, deuda) {
        if(persona.sueldoRestante() > deuda.monto()) {
            persona.restarASueldo(deuda.monto())
            deuda.pagarCuota()
        }
        return persona.sueldoRestante() > deuda.monto()
    }
}

class CreditoInfinito inherits Credito {
    override method pagar(obj, propietario) {
        propietario.inventario().add(obj)
    }

    override method sumaDeDeuda() = 0
    override method totalImpago() = 0

    override method cuandoPasaMes(propietario) {}
}

class Deuda {
    var property monto
    var property cantCuotas
    var property cantVencidas = 0

    method total() = monto * cantCuotas

    method pagarCuota() { cantCuotas -= 1; if (cantVencidas > 0) { cantVencidas -= 1} }
    method vencerCuota() { if(cantVencidas < cantCuotas) { cantVencidas += 1 } }
    method totalImpago() = monto * (1 + cantVencidas)

    override method toString() = "Deuda de " + cantCuotas + " cuotas de $" + monto + " cada una. " + cantVencidas + " cuotas están pasadas de fecha."
}

object bancos {
    const property tasaInteres = 1.02
    const property a3 = object {
        const property maximo = 12000
        const property cuotas = 3
    }
    const property b6 = object {
        const property maximo = 12000
        const property cuotas = 6
    }
    const property c24 = object {
        const property maximo = 12000
        const property cuotas = 24
    }
}

class CompradorCompulsivo inherits Persona {
    override method comprar(obj) {
        super(obj)
        if (!inventario.contains(obj)) {
            var pudoPagar = false
            formasDePago.forEach({formaDePago =>
                if (!pudoPagar && formaDePago != formaDePagoPreferida) {
                    formaDePago.pagar(obj, self)
                    if (inventario.contains(obj)) { pudoPagar = true }
                }
            })
        }
    }
}

class PagadorCompulsivo inherits Persona {
    override method cobrarSueldo() {
        sueldoRestante = salario
        formasDePago.forEach({ formaDePago => 
        formaDePago.cuandoPasaMes(self)
        if (formaDePago.totalImpago() > 0) {
            sueldoRestante += efectivo.dinero()
            efectivo.dinero(0)
            formaDePago.cuandoPasaMes(self)
        }
        })
        efectivo.sumarADinero(sueldoRestante)
        sueldoRestante = 0
    }
}

// Ejemplos de personas (para uso en tests)
const lionel = new Persona(dineroInicial = 1000, salario = 1500, formasDePago = [
    new Debito(dinero = 0),
    new Debito(dinero = 4000),
    new Credito(bancoEmisor = bancos.a3()),
    new Credito(bancoEmisor = bancos.b6()),
    new Credito(bancoEmisor = bancos.c24())
])

const any = new PagadorCompulsivo(dineroInicial = 1000, salario = 1500)

const benja = new CompradorCompulsivo(dineroInicial = 1000, salario = 0)

const cony = new Persona(dineroInicial = 1000, salario = 4000)

object personas {
    const property lista = [lionel, any, benja, cony]
    method elQueMasTiene() {
        var mejor = lista.first()
        lista.forEach({persona => 
            if(persona.inventario().size() > mejor.inventario().size()) mejor = persona
        })
        return mejor
    }
}

// Ejemplos de Objetos (para uso en tests)

object casa {
  const property casa = 2000
  const property nombre = "Casa"
}

object auto {
  const property precio = 1000
  const property nombre = "Auto"
}

object heladera {
  const property precio = 800
  const property nombre = "Heladera"
}

object microondas {
  const property precio = 400
  const property nombre = "Microondas"
}
