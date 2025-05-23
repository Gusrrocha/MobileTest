import 'package:casadosushi/carrinho_provider.dart';
import 'package:casadosushi/database/auth.dart';
import 'package:casadosushi/models/item.dart';
import 'package:casadosushi/models/pedido.dart';
import 'package:casadosushi/repositories/item_repository.dart';
import 'package:casadosushi/repositories/pedido_repository.dart';
import 'package:casadosushi/repositories/usuario_repository.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';


class CompraPage extends StatefulWidget{
  const CompraPage({super.key, required this.itens});

  final List<Item> itens;

  @override
  CompraPageState createState() => CompraPageState();
}

class CompraPageState extends State<CompraPage>{
  int _passo = 0;
  final TextEditingController cartaoController = TextEditingController();
  final TextEditingController validadeController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController complementoController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  final TextEditingController estadoController = TextEditingController();
  final TextEditingController ruaController = TextEditingController();

  final UsuarioRepository usuarioRepository = UsuarioRepository();
  final Auth auth = Auth();
  final List payments = [
    "Dinheiro",
    "Cartão de crédito",
    "Cartão de débito"
  ];
  final PedidoRepository pedidoRepository = PedidoRepository();
  final ItemRepository itemRepository = ItemRepository();

  final _cartaoFormatter = MaskTextInputFormatter(mask: "#### #### #### ####", filter: {"#": RegExp(r'[0-9]')});
  final _validadeFormatter = MaskTextInputFormatter(mask: "##/##", filter: {"#": RegExp(r'[0-9]')});
  final _cvvFormatter = MaskTextInputFormatter(mask: "###", filter: {"#": RegExp(r'[0-9]')});
  final _cpfFormatter = MaskTextInputFormatter(mask: "###.###.###-##", filter: {"#": RegExp(r'[0-9]')});
  final _cepFormatter = MaskTextInputFormatter(mask: "#####-###", filter: {"#": RegExp(r'[0-9]')});


  String paymentMethod = "";
  int selectedMonth = 0;
  void goToStep(int passo){
    setState((){
      _passo = passo;
    });
  }  

  final _formKey = GlobalKey<FormState>();  
  final _formKeyEndereco = GlobalKey<FormState>();

  _finalizarCompra(double valorTotal) async{
    DateTime data = DateTime.now();
    String formattedDate = "${data.day}/${data.month}/${data.year}";
    Pedido pedido = Pedido(listaItens: widget.itens, 
                          idUsuario: await usuarioRepository.getUserIdByUID(await auth.usuarioAtual()), 
                          data: formattedDate, 
                          valor: valorTotal, 
                          paymentMethod: paymentMethod, 
                          parcelas: paymentMethod == "Cartão de crédito" ? selectedMonth : null,
                          cep: cepController.text,
                          rua: ruaController.text,
                          numero: numeroController.text,
                          complemento: complementoController.text,
                          bairro: bairroController.text,
                          cidade: cidadeController.text,
                          estado: estadoController.text
                          );

    final pedidoNew = await pedidoRepository.createPedido(pedido);
    for(var item in widget.itens){
      item.idPedido = pedidoNew.id;
      await itemRepository.createItem(item);
    }
    
  }

  Widget _buildStep(){
    switch(_passo){
      case 0:
        return paginaInicial();
      case 1:
        return cartaoModal();
      case 2:
        return tabelaMeses();
      case 3:
        return inserirEndereco();
      case 4:
        return sumario();
      case 5:
        return telaFinal();
      default:
        return const Text("Nenhum passo encontrado");
    }
  }

  Widget paginaInicial(){
    
    return Container(
          padding: EdgeInsets.all(8),
          child: Column(
          children: [
            for (var payM in payments)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.125,
                width: MediaQuery.of(context).size.width *.95,
                child: Container(        
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color.fromARGB(64, 0, 0, 0),width: 1),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.white,
                    ),
                    child: InkWell(
                    onTap: (){
                      setState(() {
                        paymentMethod = payM;
                      });
                      if(paymentMethod == "Cartão de crédito" || paymentMethod == "Cartão de débito"){
                        goToStep(1);
                      }
                      else{
                        goToStep(3);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        payM == "Dinheiro" ? Icon(Icons.wallet, size: 40,) : Icon(Icons.credit_card, size: 40),
                        SizedBox(width: 10),
                        Text(payM, style: TextStyle(fontWeight: FontWeight.bold), textScaler: TextScaler.linear(1.25),),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              
            ],
          ),
        );
  }

  Widget cartaoModal(){
    return Container(
      height: 500,
      padding: EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
              TextFormField(
                controller: cartaoController,
                validator: (value){
                  if(value == null || value.isEmpty || value.length < 16){
                    return "Campo obrigatório";
                  }
                  return null;
                }, 
                inputFormatters: [_cartaoFormatter],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Número do Cartão",
                  border: OutlineInputBorder(),
                ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: nomeController,
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Campo obrigatório";
                }
                return null;
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Nome no Cartão",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(0,0,8,0),
                    width: 100,
                    child: TextFormField(
                      controller: validadeController,
                      validator: (value){
                        if(value == null || value.isEmpty || value.length < 5){
                          return "Campo obrigatório";
                        }
                        return null;
                      },
                      inputFormatters: [_validadeFormatter],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Validade",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.fromLTRB(0,0,8,0),
                    width: 100,
                    child: TextFormField(
                      controller: cvvController,
                      validator: (value){
                        if(value == null || value.isEmpty || value.length < 3){
                          return "Campo obrigatório";
                        }
                        return null;
                      },
                      inputFormatters: [_cvvFormatter],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "CVV",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: TextFormField(
                      controller: cpfController,
                      validator: (value){
                        if(value == null || value.isEmpty || value.length < 14){
                          return "Campo obrigatório";
                        }
                        return null;
                      },
                      inputFormatters: [_cpfFormatter],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "CPF",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
            ),       
            SizedBox(height: 20),
            Container(
              height: 55,
              width: MediaQuery.of(context).size.width *.95,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color.fromARGB(255, 204, 96, 82),
              ),
              child: TextButton(
                onPressed: () {
                  if(_formKey.currentState!.validate()){
                    if(paymentMethod == "Cartão de crédito"){
                      goToStep(2);
                    }
                    else{
                      goToStep(3);
                    }
                  }
                }, 
                child: Text("Prosseguir", style: TextStyle(color: Colors.white))
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget tabelaMeses(){
    double valorTotal = 0.0;
    if(context.read<CarrinhoProvider>().carrinho.isEmpty){
      for(var item in widget.itens){
        valorTotal += item.produto!.value * item.quantidade;
      }
    }
    else{
      valorTotal = context.read<CarrinhoProvider>().total;
    }
    return Container(
      height: 700,
      padding: EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: 12,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("${index + 1}x"),
            trailing: Text("R\$ ${(valorTotal / (index + 1)).toStringAsFixed(2).replaceAll('.', ',')}"),
            onTap: () {
              setState(() {
                selectedMonth = index + 1;
              });
              goToStep(3);
            },
          );
        },
      ),
    );
  }

  Widget inserirEndereco(){
    return Container(
      height: 500,
      padding: EdgeInsets.all(12),
      child: Form(
        key: _formKeyEndereco,
        child: Column(
          children: [
            TextFormField(
              controller: cepController,
              validator: (value){
                if(value == null || value.isEmpty || value.length < 9){
                  return "Campo obrigatório";
                }
                return null;
              },
              inputFormatters: [_cepFormatter],
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "CEP",
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: ruaController,
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Campo obrigatório";
                }
                return null;
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Rua",
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: numeroController,
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Campo obrigatório";
                }
                return null;
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Número",
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: complementoController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Complemento",
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: bairroController,
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Campo obrigatório";
                }
                return null;
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Bairro",
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: cidadeController,
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Campo obrigatório";
                }
                return null;
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Cidade",
                border: OutlineInputBorder(),
              ),
            ),
            TextFormField(
              controller: estadoController,
              validator: (value){
                if(value == null || value.isEmpty){
                  return "Campo obrigatório";
                }
                return null;
              },
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Estado",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if(_formKeyEndereco.currentState!.validate()){
                  goToStep(4);
                }
              }, 
              child: Text("Prosseguir")
            )
          ],
        ),
      ),
    );
  }
  Widget sumario(){
    double valorTotal = 0.0;
    if(context.read<CarrinhoProvider>().carrinho.isEmpty){
      for(var item in widget.itens){
        valorTotal += item.produto!.value * item.quantidade;
      }
    }
    else{
      valorTotal = context.read<CarrinhoProvider>().total;
    }
    return Container(
      child: Column(
        children: [
          Text("Resumo da Compra"),
          SizedBox(height: 20),
          for (var item in widget.itens)
            Text("${item.produto?.name} - R\$ ${item.produto?.value} x ${item.quantidade}"),
            if(paymentMethod == "Cartão de crédito")
              Text("Parcelas: $selectedMonth x R\$ ${(valorTotal / selectedMonth).toStringAsFixed(2).replaceAll('.', ',')}"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await _finalizarCompra(valorTotal);
              if(!mounted) return;
              final carrinhoprovider = Provider.of<CarrinhoProvider>(context, listen: false);

              carrinhoprovider.clearCarrinho();
              goToStep(5);
            },
            child: Text("Finalizar Compra"),
          ),
        ],
      ),
    );
  }

  Widget telaFinal(){
    return Container(
      child: Column(
        children: [
          Text("Compra finalizada com sucesso!"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async{           
              Navigator.of(context).pop();
            },
            child: Text("Voltar para o início"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: 
                        _passo == 0 ?
                          Text("Selecionar Método de Pagamento", style: TextStyle(color: Colors.white)) 
                        : _passo == 1 ? Text("Inserir Dados do Cartão", style: TextStyle(color: Colors.white))
                        : _passo == 2 ? Text("Selecionar parcelas", style: TextStyle(color: Colors.white))
                        : _passo == 3 ? Text("Endereço", style: TextStyle(color: Colors.white))
                        : _passo == 4 ? Text("Sumário", style: TextStyle(color: Colors.white))
                        : Text(''), 
                    elevation: _passo == 5 ? 0 : 1,
                    backgroundColor: _passo == 5 ? Colors.transparent : Theme.of(context).primaryColor,
                    centerTitle: true,
                    leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: _passo != 5 ? Colors.white : Colors.black),
                    onPressed: () {
                      if (_passo == 0 || _passo == 5) {
                        Navigator.pop(context); // leave screen
                      } else {
                        if(_passo == 3){
                          if(paymentMethod == "Dinheiro"){
                            setState(() {
                              _passo -= 3;
                            });
                          }
                          if(paymentMethod == "Cartão de débito"){
                            setState(() {
                              _passo -= 2;
                            });
                          }
                          if(paymentMethod == "Cartão de crédito"){
                            setState(() {
                              _passo -= 1;
                            });
                          }
                          cepController.clear();
                          numeroController.clear();
                          complementoController.clear();
                          bairroController.clear();
                          cidadeController.clear();
                          estadoController.clear();
                        }
                        else{
                          if((paymentMethod == "Cartão de crédito" || paymentMethod == "Cartão de débito") && _passo == 1){
                            cartaoController.clear();
                            validadeController.clear();
                            cvvController.clear();
                            nomeController.clear();
                            cpfController.clear();
                          }
                          setState(() {
                          _passo -= 1; // go back one step
                          }); 
                        }                    
                      }
                    },
                  ),
                ),
      backgroundColor: const Color.fromARGB(255, 250, 250, 250),
      body: _buildStep()
      );
  }
}
