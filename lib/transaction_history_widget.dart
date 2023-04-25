import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'number_format_util.dart';
import 'lonely_model.dart';
import 'transaction.dart';

class TransactionHistoryWidget extends StatefulWidget {
  const TransactionHistoryWidget({
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _TransactionHistoryState();
}

List<DataCell> _dataCellListFromTransaction(
    Transaction t, String stockName, String accountName) {
  return <DataCell>[
    DataCell(Text(t.dateTime.toIso8601String().substring(5, 10))),
    DataCell(ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 40),
        child: Text(
          accountName,
          overflow: TextOverflow.ellipsis,
        ))),
    DataCell(Text(
        '${t.transactionType == TransactionType.buy ? '🔸' : '🔹'}$stockName')),
    DataCell(Text(formatThousands(t.price))),
    DataCell(Text(formatThousands(t.count))),
    DataCell(Text(t.transactionType == TransactionType.buy
        ? ''
        : formatThousandsStr(t.earn?.toString() ?? '???'))),
  ];
}

class _TransactionHistoryState extends State<TransactionHistoryWidget> {
  final selectedSet = <int>{};

  void _showSimpleError(String msg) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
    ));
  }

  DataRow _dataRowFromTransaction(Transaction e, LonelyModel model) {
    final stock = model.getStock(e.stockId);
    final account = model.getAccount(e.accountId);

    return DataRow(
      cells: _dataCellListFromTransaction(
          e, stock?.name ?? '? ${e.stockId} ?', account.name),
      selected: selectedSet.contains(e.id),
      color: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Theme.of(context).colorScheme.primary.withOpacity(0.22);
        }
        return null; // Use the default value.
      }),
      onSelectChanged: (value) {
        if (kDebugMode) {
          //print(value);
        }
        if (e.id != null) {
          setState(() {
            if (value ?? false) {
              selectedSet.add(e.id!);
            } else {
              selectedSet.remove(e.id!);
            }
          });
        }
      },
      onLongPress: () {
        if (selectedSet.isEmpty) {
          _showSimpleError('하나 이상 선택하고 롱 탭하세요.');
          return;
        }

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('확인'),
                  content: Text('선택한 매매 기록 ${selectedSet.length}건을 모두 지울까요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'Cancel'),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, 'OK');
                        removeSelectedTransaction(model);
                      },
                      child: const Text('삭제'),
                    ),
                  ],
                ),
            barrierDismissible: true);
      },
    );
  }

  void removeSelectedTransaction(LonelyModel model) {
    model.removeTransaction(selectedSet.toList());

    setState(() {
      selectedSet.clear();
    });
  }

  @override
  void initState() {
    if (kDebugMode) {
      //print('initState(): TransactionHistoryWidget');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LonelyModel>(
      builder: (context, model, child) {
        final dataRowList = model.transactions.reversed
            .map((e) => _dataRowFromTransaction(e, model))
            .toList();

        return FittedBox(
          child: DataTable(
            showCheckboxColumn: false,
            headingRowHeight: 30,
            dataRowHeight: 30,
            columnSpacing: 30,
            columns: const [
              DataColumn(
                label: Text(
                  '날짜',
                ),
              ),
              DataColumn(
                label: Text(
                  '계좌',
                ),
              ),
              DataColumn(
                label: Text(
                  '종목명',
                ),
              ),
              DataColumn(
                label: Text(
                  '단가',
                ),
              ),
              DataColumn(
                label: Text(
                  '수량',
                ),
              ),
              DataColumn(
                label: Text(
                  '수익',
                ),
              ),
            ],
            rows: dataRowList,
          ),
        );
      },
    );
  }
}
