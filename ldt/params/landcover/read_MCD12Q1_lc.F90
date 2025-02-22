!-----------------------BEGIN NOTICE -- DO NOT EDIT-----------------------
! NASA Goddard Space Flight Center
! Land Information System Framework (LISF)
! Version 7.4
!
! Copyright (c) 2022 United States Government as represented by the
! Administrator of the National Aeronautics and Space Administration.
! All Rights Reserved.
!-------------------------END NOTICE -- DO NOT EDIT-----------------------
#include "LDT_misc.h"
!BOP
!
! !ROUTINE: read_MCD12Q1_lc
!  \label{read_MCD12Q1_lc}
!
! !REVISION HISTORY:
!  03 June 2022: Sujay Kumar; Initial Specification
!
! !INTERFACE:
subroutine read_MCD12Q1_lc(n, num_types, fgrd, maskarray )

! !USES:
  use LDT_coreMod,     only : LDT_rc
  use LDT_logMod,      only : LDT_logunit, LDT_getNextUnitNumber, &
            LDT_releaseUnitNumber, LDT_verify, LDT_endrun
  use LDT_gridmappingMod    
  use LDT_fileIOMod
  use LDT_paramTileInputMod, only: param_index_fgrdcalc
#if ( defined USE_NETCDF3 || defined USE_NETCDF4 )
  use netcdf
#endif
  
  implicit none

! !ARGUMENTS: 
  integer, intent(in) :: n
  integer, intent(inout) :: num_types
  real, intent(inout) :: fgrd(LDT_rc%lnc(n),LDT_rc%lnr(n),LDT_rc%nt)
  real, intent(inout) :: maskarray(LDT_rc%lnc(n),LDT_rc%lnr(n))
!
! !DESCRIPTION:
!  This subroutine reads the MODIS Terra+Aqua landcover data and returns the 
!  distribution of vegetation in each grid cell, in a lat/lon
!  projection.  Also, the landmask is either generated and/or 
!  read in this routine.
!
!  The arguments are:
!  \begin{description}
!   \item[n]
!     index of nest
!   \item[fgrd]
!     fraction of grid covered by each vegetation type
!   \item[maskarray]
!     landmask for the region of interest
!   \end{description}
!EOP      
!
! IGBP-NCEP landcover version:
   integer, parameter :: IN_cols_igbpncep = 86400 
   integer, parameter :: IN_rows_igbpncep = 43200
   real,    parameter :: IN_xres = 1.0/240.0
   real,    parameter :: IN_yres = 1.0/240.0
!   character*1 :: read_igbpncep_veg(IN_cols_igbpncep,IN_rows_igbpncep)
   integer, allocatable :: read_igbpncep_veg(:,:)

   integer :: ftn, ierr, ios1, lcid
   logical :: file_exists
   integer :: i, t, c, r, line
   integer :: input_cols, input_rows
   integer :: glpnc, glpnr               ! Parameter (global) total columns and rows
   integer :: subpnc, subpnr             ! Parameter subsetted columns and rows
   integer :: mi                         ! Total number of input param grid array points
   integer :: mo                         ! Total number of output LIS grid array points
   real    :: param_gridDesc(20)         ! Input parameter grid desc array
   real    :: subparam_gridDesc(20)      ! Subsetted parameter grid desc array
   integer, allocatable  :: lat_line(:,:), lon_line(:,:)
   real,    allocatable  :: gi(:)        ! Input parameter 1d grid
   logical*1,allocatable :: li(:)        ! Input logical mask (to match gi)
   real      :: go1(LDT_rc%lnc(n)*LDT_rc%lnr(n))            ! Output lis 1d grid
   logical*1 :: lo1(LDT_rc%lnc(n)*LDT_rc%lnr(n))            ! Output logical mask (to match go)
   real      :: go2(LDT_rc%lnc(n)*LDT_rc%lnr(n), LDT_rc%nt) ! Output lis 1d grid
   logical*1 :: lo2(LDT_rc%lnc(n)*LDT_rc%lnr(n), LDT_rc%nt) ! Output logical mask (to match go)

   real, allocatable :: subset_veg(:,:)  ! Read input parameter
   real      :: vegcnt(LDT_rc%lnc(n),LDT_rc%lnr(n),LDT_rc%nt)
   real      :: vegtype(LDT_rc%lnc(n),LDT_rc%lnr(n))

!__________________________________________________________________

   num_types = 20

!- Check if land cover file exists:
   inquire( file=trim(LDT_rc%vfile(n)), exist=file_exists )
   if(.not. file_exists) then
      write(LDT_logunit,*)"[ERR] The landcover map: ",trim(LDT_rc%vfile(n))," does not exist."
      write(LDT_logunit,*)" Program stopping ..."
      call LDT_endrun
   endif

   write(LDT_logunit,*) "[INFO] Reading landcover file: ",trim(LDT_rc%vfile(n))

!- Open LDT land cover file:
   select case ( LDT_rc%lc_type(n) )

    case ( "IGBPNCEP" )

   !- Assign additional land cover types, including generic water points: 
      LDT_rc%wetlandclass = 11
      LDT_rc%urbanclass   = 13
      LDT_rc%snowclass    = 15
      LDT_rc%glacierclass = 15
      LDT_rc%bareclass    = 16
      LDT_rc%waterclass   = 17

      input_cols = IN_cols_igbpncep
      input_rows = IN_rows_igbpncep

   !- Set parameter grid array inputs:
      param_gridDesc(1)  = 0.          ! Latlon
      param_gridDesc(2)  = input_cols
      param_gridDesc(3)  = input_rows
      param_gridDesc(4)  = -90.0  + (IN_yres/2) ! LL lat
      param_gridDesc(5)  = -180.0 + (IN_xres/2) ! LL lon
      param_gridDesc(6)  = 128
      param_gridDesc(7)  =  90.0 - (IN_yres/2)  ! UR lat
      param_gridDesc(8)  = 180.0 - (IN_xres/2)  ! UR lon
      param_gridDesc(9)  = IN_xres     ! dx: 0.0083333
      param_gridDesc(10) = IN_yres     ! dy: 0.0083333
      param_gridDesc(20) = 64

! --------------------------------
!    case ( "IGBP" )
!    case ( "UMD" )
!    case ( "PFT" )

!- Other landcover classifications associated with MODIS landcover:
    case default  ! Non-supported options
      write(LDT_logunit,*) "[ERR] The native MODIS map with land classification: ",&
                             trim(LDT_rc%lc_type(n)),", is not yet supported."
      write(LDT_logunit,*) " -- Please select: IGBPNCEP "
      write(LDT_logunit,*) " Program stopping ..."
      call LDT_endrun

   end select

! -------------------------------------------------------------------
!    PREPARE SUBSETTED PARAMETER GRID FOR READING IN NEEDED DATA
! -------------------------------------------------------------------

!- Map Parameter Grid Info to LIS Target Grid/Projection Info -- 
   subparam_gridDesc = 0.
   call LDT_RunDomainPts( n, LDT_rc%lc_proj, param_gridDesc(:), &
        glpnc, glpnr, subpnc, subpnr, subparam_gridDesc, lat_line, lon_line )
   

      ! Open file:
#if ( defined USE_NETCDF3 || defined USE_NETCDF4 )
   ierr = nf90_open(path=trim(LDT_rc%vfile(n)),mode=NF90_NOWRITE,ncid=ftn)
   call LDT_verify(ierr,'error opening MCD12Q1 landcover data')
   
   ierr = nf90_inq_varid(ftn,'LC_Type1',lcId)
   call LDT_verify(ierr, 'nf90_inq_varid failed for LC_Type1in read_MCD12Q1_lc')
   allocate( read_igbpncep_veg(subpnc,subpnr))

   ierr = nf90_get_var(ftn,lcId, read_igbpncep_veg,&
        count=(/subpnc,subpnr/), &
        start=(/lon_line(1,1),lat_line(1,1)/))
   call LDT_verify(ierr, 'nf90_get_var failed for LC_Type1')

   ierr = nf90_close(ftn)
   call LDT_verify(ierr)
#endif
         
   write(LDT_logunit,*) "[INFO] Done reading ", trim(LDT_rc%vfile(n))

! -------------------------------------------------------------------
   vegcnt   = 0.
   vegtype  = float(LDT_rc%waterclass)
   maskarray= 0.0
   fgrd     = 0.0

   allocate( subset_veg(subpnc, subpnr) )
   subset_veg = LDT_rc%waterclass

!- Subset parameter read-in array:
   line = 0
   do r = 1, subpnr
      do c = 1, subpnc
         if(read_igbpncep_veg(c,r).ne.255) then 
            subset_veg(c,r) = real(read_igbpncep_veg(c,r))
         else
            subset_veg(c,r) = real(LDT_rc%waterclass)
         endif
      enddo
   enddo

!   print*, subparam_gridDesc(1:10)
!   open(100,file='test.bin',form='unformatted')
!   write(100) subset_veg
!   close(100)
!   stop
   
! -------------------------------------------------------------------
   
   deallocate( read_igbpncep_veg )
! -------------------------------------------------------------------
!     AGGREGATING FINE-SCALE GRIDS TO COARSER LIS OUTPUT GRID
! -------------------------------------------------------------------
   mi = subpnc*subpnr
   allocate( gi(mi), li(mi) )
   gi = float(LDT_rc%waterclass)
   li = .false.
   mo = LDT_rc%lnc(n)*LDT_rc%lnr(n)
   lo1 = .false.;  lo2 = .false.

!- Assign 2-D array to 1-D for aggregation routines:
   i = 0
   do r = 1, subpnr
      do c = 1, subpnc;  i = i + 1
         gi(i) = subset_veg(c,r)
         if( gi(i) .ne. LDT_rc%udef ) li(i) = .true.
      enddo
   enddo

!- Aggregation/Spatial Transform Section:
   select case ( LDT_rc%lc_gridtransform(n) )

  !- (a) Estimate NON-TILED dominant land cover types (vegtype):
     case( "neighbor", "mode" )

    !- Transform parameter from original grid to LIS output grid:
       call LDT_transform_paramgrid(n, LDT_rc%lc_gridtransform(n), &
                subparam_gridDesc, mi, 1, gi, li, mo, go1, lo1 )

    !- Convert 1D vegcnt to 2D grid arrays:
       i = 0
       do r = 1, LDT_rc%lnr(n)
          do c = 1, LDT_rc%lnc(n)
             i = i + 1
             vegtype(c,r) = go1(i)
          enddo
       enddo
       
  !- (b) Estimate TILED land cover files (vegcnt):
     case( "tile" )

     !- Transform parameter from original grid to LIS output grid:
        call LDT_transform_paramgrid(n, LDT_rc%lc_gridtransform(n), &
                 subparam_gridDesc, mi, LDT_rc%nt, gi, li, mo, go2, lo2 )

     !- Convert 1D vegcnt to 2D grid arrays:
        i = 0
        do r = 1, LDT_rc%lnr(n) 
           do c = 1, LDT_rc%lnc(n)  
              i = i + 1
              do t = 1, LDT_rc%nt
                 vegcnt(c,r,t) = go2(i,t)
              end do
           enddo
        enddo

   end select  ! End vegtype/cnt aggregation method
   deallocate( gi, li )

! ........................................................................

!- Bring 2-D Vegtype to 3-D Vegcnt tile space:
   if ( LDT_rc%lc_gridtransform(n) == "none"     .or. &    ! -- NON-TILED SURFACES
        LDT_rc%lc_gridtransform(n) == "neighbor" .or. &
        LDT_rc%lc_gridtransform(n) == "mode" ) then  

     do r = 1, LDT_rc%lnr(n)
        do c = 1, LDT_rc%lnc(n)
           if ( vegtype(c,r) .le. 0 ) then
              vegtype(c,r) = float(LDT_rc%waterclass)
           endif
           if ( (nint(vegtype(c,r)) .ne. LDT_rc%waterclass ) .and. &
                (nint(vegtype(c,r)) .ne. LDT_rc%udef)) then
              vegcnt(c,r,NINT(vegtype(c,r))) = 1.0
           endif
        enddo
     end do
   endif   ! End NON-TILED vegetation option

!- Estimate fraction of grid (fgrid) represented by vegetation type::
   call param_index_fgrdcalc( n, LDT_rc%lc_proj, LDT_rc%lc_gridtransform(n), &
        LDT_rc%waterclass, LDT_rc%nt, vegcnt, fgrd )

   
! -------------------------------------------------------------------
!    CREATE OR READ-IN (OR IMPOSE) LAND MASK FILE AND CREATE
!    SURFACE MAP
! -------------------------------------------------------------------

!- "READ-IN" land mask file, if user-specified:
   if( LDT_rc%mask_type(n) == "readin" ) then

      call read_maskfile( n, vegtype, fgrd, maskarray )

!- "CREATE" land mask and surface type fields (user-specified):
   elseif( LDT_rc%mask_type(n) == "create" ) then

      call create_maskfile( n, LDT_rc%nt, LDT_rc%lc_gridtransform(n), &
                  vegtype, vegcnt, maskarray )

   end if
   deallocate( subset_veg )
   

end subroutine read_MCD12Q1_lc
