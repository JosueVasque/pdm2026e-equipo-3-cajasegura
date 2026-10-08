import 'package:flutter/material.dart';
import '../../domain/modelos/caja.dart';
import '../../domain/casos_uso/verificar_retiro_seguro.dart';
import '../../presentation/pantallas/impacto_caja_screen.dart';

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
    final monto = double.tryParse(_controlador.text.trim());

    if (monto == null || monto <= 0) {
      setState(() => _error = 'Ingresa un monto válido mayor a 0');
      return;
    }

    setState(() => _error = null);
    final resultado = VerificarRetiroSeguro()(widget.caja, monto);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImpactoCajaScreen(
          caja: widget.caja,
          resultado: resultado,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retiro Personal')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Cuánto quieres retirar como sueldo?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controlador,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: 'Q ',
                labelText: 'Monto a retirar',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const Spacer(),
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
    );
  }
}