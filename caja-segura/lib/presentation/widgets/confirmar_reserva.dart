import 'package:flutter/material.dart';
import 'formato.dart';

Future<bool> confirmarReserva(BuildContext context, int faltante) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Esta corrección utiliza la reserva'),
        content: Text(
          'Faltarían ${dineroCentavos(faltante)} para cubrir los insumos. ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    ) ??
    false;
