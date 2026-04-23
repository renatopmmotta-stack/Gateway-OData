@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.sqlViewName: 'ZRMOSFLIGHT'

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Vôo'

@Metadata.ignorePropagatedAnnotations: true

define view ZRMOCDS_Voo
  as select from sflight
  association to parent ZRMOCDS_HorarioVoo as _HorarioVoo on  $projection.Carrid = _HorarioVoo.Carrid
                                                          and $projection.Connid = _HorarioVoo.Connid

{
  key carrid     as Carrid,
  key connid     as Connid,
  key fldate     as Fldate,

      price      as Price,
      currency   as Currency,
      planetype  as Planetype,
      seatsmax   as Seatsmax,
      seatsocc   as Seatsocc,
      paymentsum as Paymentsum,
      seatsmax_b as SeatsmaxB,
      seatsocc_b as SeatsoccB,
      seatsmax_f as SeatsmaxF,
      seatsocc_f as SeatsoccF,
      
      _HorarioVoo
}
