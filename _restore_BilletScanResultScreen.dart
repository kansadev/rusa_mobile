/*     if (!mounted) return;

    final success = result.success;

    setState(() {
      _embarquementLoading = false;
      if (success) {
        _embarquementOk = true;
        if (result.billet != null) {
          _billetCourant = result.billet;
        } else {
          final prev = _billetCourant;
          if (prev != null) {
            _billetCourant = BilletData(
              id: prev.id,
              qrCode: prev.qrCode,
              dateGeneration: prev.dateGeneration,
              idReservation: prev.idReservation,
              idClient: prev.idClient,
              idSociete: prev.idSociete,
              urlBillet: prev.urlBillet,
              idReservationPassenger: prev.idReservationPassenger,
              isUsed: true,
            );
          }
        }
      } else {
        _embarquementErreur = result.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    });

    if (success && mounted) {
      await _feedbackEmbarquementReussi();
    }
  } */