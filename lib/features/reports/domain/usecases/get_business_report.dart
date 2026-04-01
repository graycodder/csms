import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';
import 'package:csms/features/reports/domain/repositories/report_repository.dart';

class GetBusinessReport {
  final ReportRepository repository;

  GetBusinessReport(this.repository);

  Future<Either<Failure, ReportEntity>> call({
    required String shopId,
    required String ownerId,
    required ReportFilter filter,
    DateTime? referenceDate,
  }) {
    return repository.getReport(
      shopId: shopId,
      ownerId: ownerId,
      filter: filter,
      referenceDate: referenceDate,
    );
  }
}
