import os
import tkinter as tk
from tkinter import messagebox
import cv2
import numpy as np
import easyocr

# --- Configurazione ---
NOME_FILE_TCL = "sudoku15.tcl"
PATH_DOWNLOAD = "" #"/storage/emulated/0/Download"
PERCORSO_ASSOLUTO = os.path.join(PATH_DOWNLOAD, NOME_FILE_TCL)

# --- Inizializza EasyOCR una sola volta ---
ocr_reader = None

def scan_camera():
    global ocr_reader
    try:
        # Apri la fotocamera
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            messagebox.showerror("Errore", "Impossibile aprire la fotocamera.")
            return
        ret, frame = cap.read()
        cap.release()
        if not ret:
            messagebox.showerror("Errore", "Impossibile acquisire l'immagine.")
            return

        # --- Rilevamento griglia (stesso codice di sopra) ---
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        blur = cv2.GaussianBlur(gray, (5,5), 0)
        thresh = cv2.adaptiveThreshold(blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                       cv2.THRESH_BINARY_INV, 11, 2)
        contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        grid_contour = None
        max_area = 0
        for cnt in contours:
            area = cv2.contourArea(cnt)
            if area > 1000:
                peri = cv2.arcLength(cnt, True)
                approx = cv2.approxPolyDP(cnt, 0.02 * peri, True)
                if len(approx) == 4 and area > max_area:
                    grid_contour = approx
                    max_area = area
        if grid_contour is None:
            messagebox.showerror("Errore", "Nessuna griglia Sudoku rilevata.")
            return

        pts = grid_contour.reshape(4, 2)
        rect = np.zeros((4, 2), dtype="float32")
        s = pts.sum(axis=1)
        rect[0] = pts[np.argmin(s)]
        rect[2] = pts[np.argmax(s)]
        diff = np.diff(pts, axis=1)
        rect[1] = pts[np.argmin(diff)]
        rect[3] = pts[np.argmax(diff)]
        (tl, tr, br, bl) = rect
        widthA = np.linalg.norm(br - bl)
        widthB = np.linalg.norm(tr - tl)
        maxWidth = max(int(widthA), int(widthB))
        heightA = np.linalg.norm(tr - br)
        heightB = np.linalg.norm(tl - bl)
        maxHeight = max(int(heightA), int(heightB))
        dst = np.array([[0,0], [maxWidth-1,0], [maxWidth-1,maxHeight-1], [0,maxHeight-1]], dtype="float32")
        M = cv2.getPerspectiveTransform(rect, dst)
        warped = cv2.warpPerspective(frame, M, (maxWidth, maxHeight))
        warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)

        # --- Divisione in celle e OCR ---
        cell_size = maxWidth // 9
        sudoku_matrix = [[0]*9 for _ in range(9)]
        if ocr_reader is None:
            ocr_reader = easyocr.Reader(['en'])
        for i in range(9):
            for j in range(9):
                x = j * cell_size
                y = i * cell_size
                cell = warped_gray[y:y+cell_size, x:x+cell_size]
                _, cell_th = cv2.threshold(cell, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
                if np.sum(cell_th) > 0.05 * cell_size * cell_size * 255:
                    # OCR sulla cella
                    result = ocr_reader.readtext(cell_th, paragraph=False, allowlist='123456789')
                    if result:
                        digit = int(result[0][1])
                        sudoku_matrix[i][j] = digit

        # --- Converti in formato Tcl ---
        tcl_list = "{" + "} {".join(" ".join(str(n) if n != 0 else "0" for n in row) for row in sudoku_matrix) + "}"
        tcl.eval(f"set sudoku {tcl_list}")
        tcl.eval('set filename "scansionato"')
        tcl.eval('newtext "scansionato"')
        messagebox.showinfo("Scansione completata", "Puzzle importato dalla fotocamera!")

    except Exception as e:
        messagebox.showerror("Errore", str(e))

# --- Main ---
if __name__ == "__main__":
    if not os.path.exists(PERCORSO_ASSOLUTO):
        messagebox.showerror("Errore", f"File '{NOME_FILE_TCL}' non trovato in Download!")
        raise SystemExit

    root = tk.Tk()
    root.title("Sudoku - Tcl/Tk via Python")
    tcl = root.tk

    # Carica lo script Tcl
    try:
        tcl.eval(f'source "{PERCORSO_ASSOLUTO}"')
    except tk.TclError as e:
        messagebox.showerror("Errore Tcl", f"Impossibile caricare lo script:\n{e}")
        raise

    # Registra il comando Python per Tcl
    root.tk.createcommand("scan_camera_py", scan_camera)

    # Aggiungi il pulsante "Scansiona"
    tcl.eval('button .buttons.scan -text "Scan" -command scan_camera_py')
    tcl.eval('pack .buttons.scan -side left -expand 1')

    root.mainloop()