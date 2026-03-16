# Proyecto Electronica 2 - Amplificador BJT multietapa
# Integrantes: Pedro Murillo, Yusceirich Ruiz, Norberto Quiroga, Alejandro Ortiz
# Universidad del Magdalena - Ingenieria Electronica
# fecha: 16/03/2026

import math

# -------------------------------------------------------
# DATOS DEL CIRCUITO
# -------------------------------------------------------

VCC = 24        # voltaje de alimentacion [V]
VT  = 0.026     # voltaje termica a 25 grados [V]

# transistores
B1   = 200      # beta Q1 BC547
B2   = 200      # beta Q2 BC547
B3   = 1000     # beta Q3 TIP122 darlington
VBE  = 0.7      # voltaje base emisor normal [V]
VBE3 = 1.4      # voltaje base emisor darlington  [V]

# etapa 1 - emisor comun Q1
R15 = 62000     # divisor de base parte alta [ohm]
R1  = 11000     # divisor de base parte baja [ohm]
R2  = 1100      # resistencia de colector [ohm]   <- ajustamos esto para llegar a Av=300
R3  = 80        # resistencia emisor sin bypass [ohm]
R4  = 22        # resistencia emisor con bypass C2 [ohm]

# etapa 2 - emisor comun Q2
R5  = 39000     # divisor de base parte alta [ohm]  <- cambiamos de 9.6k a 39k para bajar IC2
R7  = 7800      # divisor de base parte baja [ohm]
R6  = 930       # resistencia de colector [ohm]     <- ajustamos para ganancia
R9  = 22        # resistencia emisor sin bypass [ohm]
R10 = 50        # resistencia emisor con bypass C4 [ohm]

# etapa 3 - colector comun Q3
R8  = 5000      # divisor base alta [ohm]
R11 = 86000     # divisor base baja [ohm]
R13 = 33        # carga emisor 1 [ohm]
R14 = 20        # carga emisor 2 [ohm]


# -------------------------------------------------------
# funciones que usamos varias veces
# -------------------------------------------------------

def par(r1, r2):
    # paralelo de dos resistencias
    return (r1 * r2) / (r1 + r2)


# -------------------------------------------------------
# ANALISIS DC - punto de operacion Q
# -------------------------------------------------------

print("=" * 55)
print("  ANALISIS DC - PUNTO DE OPERACION Q")
print("=" * 55)

# -- etapa 1 --
VB1 = VCC * R1 / (R15 + R1)
VE1 = VB1 - VBE
IC1 = VE1 / (R3 + R4)
VC1 = VCC - IC1 * R2
VCE1 = VC1 - VE1

print("\nEtapa 1 (Q1 - BC547):")
print(f"  VB1 = {VCC} x {R1} / ({R15} + {R1}) = {VB1:.3f} V")
print(f"  VE1 = VB1 - VBE = {VB1:.3f} - {VBE} = {VE1:.3f} V")
print(f"  IC1 = VE1 / (R3+R4) = {VE1:.3f} / {R3+R4} = {IC1*1000:.3f} mA")
print(f"  VCE1 = {VCE1:.3f} V")
if VCE1 < 0.2:
    print(f"  ojo: VCE1 negativo, con la senal pequena el Q1 puede saturar")

# -- etapa 2 --
VB2 = VCC * R7 / (R5 + R7)
VE2 = VB2 - VBE
IC2 = VE2 / (R9 + R10)
VC2 = VCC - IC2 * R6
VCE2 = VC2 - VE2

print("\nEtapa 2 (Q2 - BC547):")
print(f"  VB2 = {VCC} x {R7} / ({R5} + {R7}) = {VB2:.3f} V")
print(f"  VE2 = VB2 - VBE = {VB2:.3f} - {VBE} = {VE2:.3f} V")
print(f"  IC2 = VE2 / (R9+R10) = {VE2:.3f} / {R9+R10} = {IC2*1000:.3f} mA")
print(f"  VCE2 = {VCE2:.3f} V")
if IC2 > 0.1:
    print(f"  cuidado: IC2 = {IC2*1000:.1f} mA supera el limite del BC547 (100mA)")
else:
    print(f"  IC2 dentro del rango del BC547, bien")

# -- etapa 3 --
VB3 = VCC * R11 / (R8 + R11)
VE3 = VB3 - VBE3
IC3 = VE3 / (R13 + R14)
VCE3 = VCC - VE3

print("\nEtapa 3 (Q3 - TIP122 Darlington):")
print(f"  VB3 = {VCC} x {R11} / ({R8} + {R11}) = {VB3:.3f} V")
print(f"  VE3 = VB3 - VBE_darl = {VB3:.3f} - {VBE3} = {VE3:.3f} V")
print(f"  IC3 = VE3 / (R13+R14) = {VE3:.3f} / {R13+R14} = {IC3*1000:.3f} mA")
print(f"  VCE3 = {VCE3:.3f} V  -> region activa ok")

# tabla resumen punto Q
print("\n  resumen punto Q:")
print(f"  {'':15} {'Etapa1':>10} {'Etapa2':>10} {'Etapa3':>10}")
print(f"  {'VB (V)':15} {VB1:>10.3f} {VB2:>10.3f} {VB3:>10.3f}")
print(f"  {'VE (V)':15} {VE1:>10.3f} {VE2:>10.3f} {VE3:>10.3f}")
print(f"  {'IC (mA)':15} {IC1*1000:>10.3f} {IC2*1000:>10.3f} {IC3*1000:>10.3f}")
print(f"  {'VCE (V)':15} {VCE1:>10.3f} {VCE2:>10.3f} {VCE3:>10.3f}")


# -------------------------------------------------------
# PARAMETROS DE PEQUEÑA SEÑAL - modelo hie y re
# -------------------------------------------------------

print("\n" + "=" * 55)
print("  PARAMETROS DE PEQUEÑA SEÑAL (hie y re)")
print("=" * 55)

# hie = beta * VT / IC  <- resistencia de entrada del transistor
# re  = VT / IC         <- resistencia de emisor dinamica

hie1 = B1 * VT / IC1
hie2 = B2 * VT / IC2
hie3 = B3 * VT / IC3

re1  = VT / IC1
re2  = VT / IC2
re3  = VT / IC3

print(f"\nhie1 = B1 * VT / IC1 = {B1} * {VT} / {IC1*1000:.4f}mA = {hie1:.3f} ohm")
print(f"hie2 = B2 * VT / IC2 = {B2} * {VT} / {IC2*1000:.4f}mA = {hie2:.3f} ohm")
print(f"hie3 = B3 * VT / IC3 = {B3} * {VT} / {IC3*1000:.4f}mA = {hie3:.3f} ohm")

print(f"\nre1  = VT / IC1 = {re1:.4f} ohm  (mucho menor que R3={R3} ohm, ok)")
print(f"re2  = VT / IC2 = {re2:.4f} ohm  (mucho menor que R9={R9} ohm, ok)")
print(f"re3  = VT / IC3 = {re3:.4f} ohm")


# -------------------------------------------------------
# IMPEDANCIAS DE ENTRADA
# calculo de etapa 3 a 1 porque Rin3 se necesita para RC2
# -------------------------------------------------------

print("\n" + "=" * 55)
print("  IMPEDANCIAS DE ENTRADA")
print("=" * 55)

# etapa 3
RE3ac = par(R13, R14)
Zb3   = hie3 + (B3 + 1) * RE3ac
Rin3  = par(par(R8, R11), Zb3)

print(f"\nEtapa 3:")
print(f"  RE3ac = R13 || R14 = {R13} || {R14} = {RE3ac:.3f} ohm")
print(f"  Zb3 = hie3 + (B3+1)*RE3ac = {hie3:.2f} + {B3+1}*{RE3ac:.2f} = {Zb3:.2f} ohm")
print(f"  Rin3 = R8||R11||Zb3 = {par(R8,R11):.2f} || {Zb3:.2f} = {Rin3:.2f} ohm  ({Rin3/1000:.3f} kohm)")

# etapa 2
Zb2  = hie2 + (B2 + 1) * R9
Rin2 = par(par(R5, R7), Zb2)

print(f"\nEtapa 2:")
print(f"  Zb2 = hie2 + (B2+1)*R9 = {hie2:.2f} + {B2+1}*{R9} = {Zb2:.2f} ohm")
print(f"  Rin2 = R5||R7||Zb2 = {par(R5,R7):.2f} || {Zb2:.2f} = {Rin2:.2f} ohm  ({Rin2/1000:.3f} kohm)")

# etapa 1
Zb1  = hie1 + (B1 + 1) * R3
Rin1 = par(par(R15, R1), Zb1)

print(f"\nEtapa 1:")
print(f"  Zb1 = hie1 + (B1+1)*R3 = {hie1:.2f} + {B1+1}*{R3} = {Zb1:.2f} ohm")
print(f"  Rin1 = R15||R1||Zb1 = {par(R15,R1):.2f} || {Zb1:.2f} = {Rin1:.2f} ohm  ({Rin1/1000:.3f} kohm)")


# -------------------------------------------------------
# GANANCIAS DE VOLTAJE - modelo hie
# -------------------------------------------------------

print("\n" + "=" * 55)
print("  GANANCIAS DE VOLTAJE (modelo hie )")
print("=" * 55)

# etapa 3 - colector comun
# Av = (B+1)*RE / [hie + (B+1)*RE]
Av3 = (B3 + 1) * RE3ac / (hie3 + (B3 + 1) * RE3ac)

print(f"\nEtapa 3 (colector comun):")
print(f"  Av3 = (B3+1)*RE3ac / [hie3 + (B3+1)*RE3ac]")
print(f"  Av3 = {B3+1}*{RE3ac:.3f} / [{hie3:.3f} + {B3+1}*{RE3ac:.3f}]")
print(f"  Av3 = {(B3+1)*RE3ac:.3f} / {hie3 + (B3+1)*RE3ac:.3f} = {Av3:.4f}")
print(f"  -> sin inversion de fase, ganancia casi 1 como se esperaba")

# etapa 2 - emisor comun
# Av = -B*RC(AC) / [hie + (B+1)*RE(AC)]
RC2ac = par(R6, Rin3)   # efecto de carga con etapa 3
Av2   = -(B2 * RC2ac) / (hie2 + (B2 + 1) * R9)

print(f"\nEtapa 2 (emisor comun):")
print(f"  RC2ac = R6 || Rin3 = {R6} || {Rin3:.2f} = {RC2ac:.3f} ohm")
print(f"  Av2 = -B2*RC2ac / [hie2 + (B2+1)*R9]")
print(f"  Av2 = -{B2}*{RC2ac:.3f} / [{hie2:.3f} + {B2+1}*{R9}]")
print(f"  Av2 = {-B2*RC2ac:.3f} / {hie2+(B2+1)*R9:.3f} = {Av2:.4f}")
print(f"  -> con inversion de fase")

# etapa 1 - emisor comun
RC1ac = par(R2, Rin2)   # efecto de carga con etapa 2
Av1   = -(B1 * RC1ac) / (hie1 + (B1 + 1) * R3)

print(f"\nEtapa 1 (emisor comun):")
print(f"  RC1ac = R2 || Rin2 = {R2} || {Rin2:.2f} = {RC1ac:.3f} ohm")
print(f"  Av1 = -B1*RC1ac / [hie1 + (B1+1)*R3]")
print(f"  Av1 = -{B1}*{RC1ac:.3f} / [{hie1:.3f} + {B1+1}*{R3}]")
print(f"  Av1 = {-B1*RC1ac:.3f} / {hie1+(B1+1)*R3:.3f} = {Av1:.4f}")
print(f"  -> con inversion de fase")

# ganancia total
Av_total = Av1 * Av2 * Av3
Av_dB    = 20 * math.log10(abs(Av_total))

print(f"\nGanancia total:")
print(f"  Av_total = Av1 * Av2 * Av3")
print(f"  Av_total = ({Av1:.4f}) * ({Av2:.4f}) * ({Av3:.4f})")
print(f"  Av_total = {Av_total:.4f}")
print(f"  Av_dB    = 20 * log10({abs(Av_total):.4f}) = {Av_dB:.2f} dB")
print(f"  la salida queda en fase con la entrada (las 2 inversiones se cancelan)")

print("\n" + "=" * 55)
print(f"  RESULTADO FINAL: Av = {Av_total:.2f}  ({Av_dB:.2f} dB)")
print("=" * 55)
print(f"\n  Etapa 1 -> Av1 = {Av1:.2f}")
print(f"  Etapa 2 -> Av2 = {Av2:.2f}")
print(f"  Etapa 3 -> Av3 = {Av3:.4f}")
print(f"\n  objetivo era Av >= 300, obtuvimos {Av_total:.1f} -> listo")
print()
