import 'package:flutter/material.dart';
import '../../domain/modelos/caja.dart';
import '../../domain/casos_uso/verificar_retiro_seguro.dart';
import '../../presentation/pantallas/impacto_caja_screen.dart';
import '../widgets/importes.dart';
import '../tema/caja_estilo.dart';

class RetiroPersonalScreen extends StatefulWidget {
  final Caja caja;
  const RetiroPersonalScreen({super.key, required this.caja});

  @override
  State<RetiroPersonalScreen> createState() => _RetiroPersonalScreenState();
}

class _RetiroPersonalScreenState extends State<RetiroPersonalScreen> {
  final _controlador = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _verificar() {
    final monto = leerImporte(_controlador.text);

    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido mayor a 0');
      return;
    }

    setState(() => _error = null);
    final resultado = VerificarRetiroSeguro()(widget.caja, monto);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ImpactoCajaScreen(caja: widget.caja, resultado: resultado),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retiro Personal')),
      body: SuperficieCaja(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: IconoCaja(
                    Icons.north_east_rounded,
                    oscuro: true,
                    tamano: 58,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '¿Cuánto quieres retirar como sueldo?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: CajaEstilo.tinta,
                  ),
                  controller: _controlador,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'Q ',
                    labelText: 'Monto a retirar',
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const IconoCaja(Icons.shield_outlined),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tu reserva se queda en el negocio',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: CajaEstilo.tinta,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Puedes retirar hasta Q${widget.caja.disponibleParaSueldo.toStringAsFixed(2)} sin tocar tus insumos.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _verificar,
                  child: const Text('Verificar si es seguro'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
