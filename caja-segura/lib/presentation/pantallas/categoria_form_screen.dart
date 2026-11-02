import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/modelos/categoria.dart';
import '../providers/categoria_provider.dart';

class CategoriaFormScreen extends ConsumerStatefulWidget {
  const CategoriaFormScreen({super.key, this.categoria});

  final Categoria? categoria;

  @override
  ConsumerState<CategoriaFormScreen> createState() =>
      _CategoriaFormScreenState();
}

class _CategoriaFormScreenState extends ConsumerState<CategoriaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  bool _guardando = false;

  bool get _esEdicion => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.categoria?.nombre ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _guardando) return;

    setState(() => _guardando = true);

    try {
      final acciones = ref.read(categoriaAccionesProvider);
      final nombre = _nombreController.text.trim();

      if (_esEdicion) {
        await acciones.actualizar(widget.categoria!.id!, nombre);
      } else {
        await acciones.crear(nombre);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar categoría' : 'Nueva categoría'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                autofocus: true,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nombre de categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el nombre de la categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: const Icon(Icons.save),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : _esEdicion
                      ? 'Guardar cambios'
                      : 'Crear categoría',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
