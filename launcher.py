import os
import tkinter as tk
from tkinter import filedialog, messagebox
import cv2
import numpy as np
import easyocr

# --- Percorso del file Tcl (modifica se necessario) ---
NOME_FILE_TCL = "sudoku15.tcl"
# Metti qui il percorso assoluto o relativo al tuo progetto
#PERCORSO_TCL = os.path.join(os.path.dirname(__file__), NOME_FILE_TCL)
PERCORSO_TCL = NOME_FILE_TCL

# --- Inizializza EasyOCR una volta sola (per performance) ---
ocr_reader = None

def get_ocr_reader():
    global ocr_reader
    if ocr_reader is None:
        ocr_reader = easyocr.Reader(['en'])  # 'en' per numeri
    return ocr_reader

def process_image(img):
    """
    Rileva la griglia Sudoku e restituisce una matrice 9x9 di numeri.
    """
    # Ridimensiona se troppo piccola
    h, w = img.shape[:2]
    if w < 300 or h < 300:
        scale = max(300/w, 300/h)
        new_w = int(w * scale)
        new_h = int(h * scale)
        img = cv2.resize(img, (new_w, new_h))
        h, w = img.shape[:2]

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    thresh = cv2.adaptiveThreshold(blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                   cv2.THRESH_BINARY_INV, 11, 2)

    # Morfologia per chiudere i gap nei bordi
    kernel = np.ones((5, 5), np.uint8)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel, iterations=3)

    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    image_area = h * w
    grid_contour = None
    max_area = 0

    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < 500:
            continue
        # Scarta contorni che coprono quasi tutta l'immagine
        if area > 0.8 * image_area:
            continue
        peri = cv2.arcLength(cnt, True)
        approx = cv2.approxPolyDP(cnt, 0.02 * peri, True)
        if len(approx) == 4:
            x, y, w_c, h_c = cv2.boundingRect(approx)
            aspect = w_c / float(h_c) if h_c != 0 else 1
            if 0.8 < aspect < 1.2 and area > max_area:
                grid_contour = approx
                max_area = area
        elif len(approx) > 4 and area > max_area:
            rect = cv2.minAreaRect(cnt)
            box = cv2.boxPoints(rect)
            box = box.astype(np.int32)
            rect_area = cv2.contourArea(box)
            if rect_area < 0.8 * image_area and rect_area > area * 1.1:
                rw = np.linalg.norm(box[0] - box[1])
                rh = np.linalg.norm(box[1] - box[2])
                aspect = rw / float(rh) if rh != 0 else 1
                if 0.8 < aspect < 1.2 and rect_area > max_area:
                    grid_contour = box
                    max_area = rect_area

    if grid_contour is None:
        debug_img = img.copy()
        cv2.drawContours(debug_img, contours, -1, (0,255,0), 2)
        cv2.imwrite("debug_contours.jpg", debug_img)
        raise ValueError("Nessuna griglia Sudoku rilevata. Salvato debug_contours.jpg")

    debug_out = img.copy()
    cv2.drawContours(debug_out, [grid_contour], 0, (0,0,255), 3)
    cv2.imwrite("debug_grid_found.jpg", debug_out)

    # --- Trasformazione prospettica ---
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

    # Assicura che le dimensioni siano multiple di 9 (per evitare arrotondamenti)
    maxWidth = (maxWidth // 9) * 9
    maxHeight = (maxHeight // 9) * 9

    dst = np.array([
        [0, 0],
        [maxWidth - 1, 0],
        [maxWidth - 1, maxHeight - 1],
        [0, maxHeight - 1]
    ], dtype="float32")

    M = cv2.getPerspectiveTransform(rect, dst)
    warped = cv2.warpPerspective(img, M, (maxWidth, maxHeight))
    warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)

    # --- Divisione in celle e OCR (con margine e dimensioni separate) ---
    cell_width = maxWidth // 9
    cell_height = maxHeight // 9
    sudoku_matrix = [[0] * 9 for _ in range(9)]
    reader = get_ocr_reader()

    margin_w = int(cell_width * 0.1)
    margin_h = int(cell_height * 0.085) #0.1

    for i in range(9):
        for j in range(9):
            x = j * cell_width + margin_w
            y = i * cell_height + margin_h
            cell_w = cell_width - 2 * margin_w
            cell_h = cell_height - 2 * margin_h
            if cell_w <= 0 or cell_h <= 0:
                continue
            #cell = warped_gray[y+10:y+cell_h-10, x+10:x+cell_w-10]
            cell = warped_gray[y:y+cell_h, x:x+cell_w]
            #print(f'cell({i},{j}):{x};{y}')

            # --- PRE-PROCESSAMENTO AVANZATO ---
            # 1. Riduci rumore (opzionale)
            #cell = cv2.bilateralFilter(cell, 9, 75, 75)

            # 2. Equalizza l'istogramma (migliora contrasto globale)
            cell_eq = cv2.equalizeHist(cell)

            # 3. Normalizza per espandere il range dinamico
            cell_norm = cv2.normalize(cell_eq, None, 0, 255, cv2.NORM_MINMAX)

            # 4. Applica soglia adattiva (OTSU su cella normalizzata)
            _, cell_th = cv2.threshold(cell_norm, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
            #cell_th = cv2.adaptiveThreshold(cell_norm, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            #                                cv2.THRESH_BINARY_INV, 11, 2)
            #print(f'cell({i},{j}): threshold done ', end='')

            # 5. (Opzionale) Inverti se predominano pixel scuri
            #if np.mean(cell) > 127:
            #    cell_th = 255 - cell_th

            # Calcola area nera per decidere se c'è un numero
            if np.sum(cell_th) > 0.2 * cell_w * cell_h * 255:
                #print(f'cell({i},{j}) # {np.sum(cell_th)} > {0.08 * cell_w * cell_h * 255}')

                # Ridimensiona la cella a 2x per OCR (Opzionale)
                #cell_resized = cv2.resize(cell_th, (0, 0), fx=2, fy=2, interpolation=cv2.INTER_CUBIC)

                # OCR sulla cella elaborata
                result = reader.readtext(cell_th, paragraph=False, allowlist='123456789')
                if result:
                    try:
                        digit = int(result[0][1])
                        print(f'cell({i},{j}) -> {digit}')
                        sudoku_matrix[i][j] = digit
                        cv2.imwrite(f"cella_{i}_{j}_{digit}.jpg", cell_th)


                    except Exception as e:
                        print(f'int: {e}')
                        pass
                else:
                    cv2.imwrite(f"cella_{i}_{j}_FAIL.jpg", cell_th)
                    print(f'cell({i},{j}): readtext FAIL')
            else:
                # La cella è considerata vuota, salviamo l'immagine per controllo
                cv2.imwrite(f"cella_{i}_{j}_vuota.jpg", cell_th)
                print(f'cell({i},{j}): VUOTA')

    for ii in range(9):
        for jj in range(9):
            print(f'{sudoku_matrix[ii][jj]}', end='')
        print('')
    print('')

    return sudoku_matrix

def update_tcl_sudoku(matrix, tcl_interp, nome="scansionato"):
    """
    Converte la matrice in formato Tcl e la carica nell'interprete.
    """
    tcl_list = "{{" + "} {".join(
        " ".join(str(n)+'.' if n != 0 else "0" for n in row)
        for row in matrix
    ) + "}}"
    tcl_interp.eval(f"set sudoku {tcl_list}")
    tcl_interp.eval(f'set filename "{nome}"')
    tcl_interp.eval('newtext "' + nome + '"')
    messagebox.showinfo("Successo", "Puzzle importato correttamente!")

def scan_camera():
    """Acquisisce un'immagine dalla webcam e la processa."""
    try:
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            messagebox.showerror("Errore", "Impossibile aprire la webcam.")
            return
        ret, frame = cap.read()
        cap.release()
        if not ret:
            messagebox.showerror("Errore", "Impossibile catturare il fotogramma.")
            return

        matrix = process_image(frame)
        update_tcl_sudoku(matrix, tcl, "webcam")

    except Exception as e:
        messagebox.showerror("Errore", f"Scansione fallita:\n{e}")

def load_image_file():
    """Apre un file dialog per selezionare un'immagine e la processa."""
    try:
        file_path = filedialog.askopenfilename(
            title="Seleziona un'immagine",
            filetypes=[("Immagini", "*.jpg *.jpeg *.png *.bmp *.tiff")]
        )
        if not file_path:
            return  # utente ha annullato

        img = cv2.imread(file_path)
        if img is None:
            messagebox.showerror("Errore", "Impossibile leggere l'immagine selezionata.")
            return

        matrix = process_image(img)
        # Usa il nome del file (senza estensione) come titolo
        nome = os.path.splitext(os.path.basename(file_path))[0]
        update_tcl_sudoku(matrix, tcl, nome)

    except Exception as e:
        messagebox.showerror("Errore", f"Caricamento fallito:\n{e}")

# --- MAIN ---
if __name__ == "__main__":
    if not os.path.exists(PERCORSO_TCL):
        messagebox.showerror("Errore", f"File Tcl non trovato:\n{PERCORSO_TCL}")
        raise SystemExit

    root = tk.Tk()
    root.title("Sudoku - Tcl/Tk con OCR")
    tcl = root.tk

    # Carica lo script Tcl
    try:
        tcl.eval(f'source "{PERCORSO_TCL}"')
    except tk.TclError as e:
        messagebox.showerror("Errore Tcl", f"Impossibile caricare lo script:\n{e}")
        raise

    # Registra i comandi Python per Tcl
    root.tk.createcommand("scan_camera_py", scan_camera)
    root.tk.createcommand("load_image_py", load_image_file)

    # Crea un secondo frame per la nuova riga (sotto .buttons)
    tcl.eval('frame .buttons2')
    tcl.eval('pack .buttons2 -side bottom -fill x -pady 2m')
    tcl.eval('button .buttons2.scan -text "Scansiona" -command scan_camera_py')
    tcl.eval('button .buttons2.loadimg -text "Carica immagine" -command load_image_py')
    tcl.eval('pack .buttons2.scan .buttons2.loadimg -side left -expand 1')

    root.mainloop()