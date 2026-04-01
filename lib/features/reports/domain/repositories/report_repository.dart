import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/reports/domain/entities/report_entity.dart';

abstract class ReportRepository {
  Future<Either<Failure, ReportEntity>> getReport({
    required String shopId,
    required String ownerId,
    required ReportFilter filter,
    DateTime? referenceDate,
  });
}
