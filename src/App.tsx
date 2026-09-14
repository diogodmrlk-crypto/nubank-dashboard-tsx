import { useEffect, useRef, useState } from 'react'
import type { ChangeEvent } from 'react'
import { ArrowDownToLine, ArrowLeft, ArrowUpRight, Building2, Calendar, ChevronRight, CircleDollarSign, CircleQuestionMark, Copy, HandCoins, HelpCircle, Key, Loader2, MoreHorizontal, QrCode, Search, SlidersHorizontal, Plus, RefreshCcw, Wallet, X, Zap } from 'lucide-react'

type EditKey = 'name' | 'balance' | 'invoice' | 'limit' | 'loan'
type Values = { name: string; balance: string; invoice: string; limit: string; loan: string }

const shortcuts = [
  { label: 'Área Pix e\nTransferir', icon: 'https://i.imgur.com/m9Df7Br.png' },
  { label: 'Pagar', icon: 'https://i.imgur.com/hF3k64P.png' },
  { label: 'Pegar\nemprestado', icon: 'https://i.imgur.com/MxxyyAO.png', tag: 'FGTS' },
  { label: 'Recarga de\ncelular', icon: 'https://i.imgur.com/wpwQ4SK.png' },
  { label: 'Caixinha e\nInvestir', icon: 'https://i.imgur.com/oFV0JMO.png' },
]

const cards = [
  ['https://i.imgur.com/7wHCsJC.jpeg', 'Seguro Vida', 'Cuide de quem você ama de um jeito simples e que cabe no seu bolso.', 'Conhecer'],
  ['https://i.imgur.com/A2oNKfG.jpeg', 'Área de Seguros do Nu', 'Toda proteção para você e para quem você ama num só lugar', 'Conhecer'],
  ['https://i.imgur.com/8EOkb0L.jpeg', 'Indique o Nu para Amigos', 'Espalhe como é simples estar no controle.', 'Indicar amigos'],
  ['https://i.imgur.com/8fCMzeO.jpeg', 'Traga seus dados', 'Mais chances de limites e produtos com a sua cara.', 'Saiba mais'],
]

const bottomIcons = {
  home: 'https://i.imgur.com/V8XplLz.png',
  money: 'https://i.imgur.com/L64YZdo.png',
  planning: 'https://i.imgur.com/FlL60GN.png',
  store: 'https://i.imgur.com/JCmXscK.png',
}

function EditDialog({ kind, value, onClose, onSave }: { kind: EditKey; value: string; onClose: () => void; onSave: (value: string) => void }) {
  const [draft, setDraft] = useState(value)
  const inputRef = useRef<HTMLInputElement>(null)
  const labels: Record<EditKey, string> = { name: 'Nome', balance: 'Saldo em conta', invoice: 'Valor da fatura', limit: 'Limite disponível', loan: 'Valor do empréstimo' }
  const isName = kind === 'name'
  useEffect(() => { inputRef.current?.focus(); inputRef.current?.select() }, [])
  return <div className="dialog-backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
    <form className="edit-dialog" onSubmit={(e) => { e.preventDefault(); if (draft.trim()) { onSave(draft.trim()); onClose() } }}>
      <button type="button" className="dialog-close" onClick={onClose} aria-label="Fechar"><X size={21} /></button>
      <span className="eyebrow">Editar informação</span><h2>{labels[kind]}</h2>
      <label className="field-label" htmlFor="edit-field">Digite o novo valor</label>
      <div className="edit-field-wrap"><span>{isName ? '' : 'R$ '}</span><input ref={inputRef} id="edit-field" inputMode={isName ? 'text' : 'decimal'} value={draft} onChange={(e) => setDraft(e.target.value)} /></div>
      <button className="primary-btn" type="submit">Salvar</button>
    </form>
  </div>
}

const pixActions = [
  { label: 'Transferir', icon: ArrowUpRight }, { label: 'Programar', icon: Calendar }, { label: 'Ler QR code', icon: QrCode },
  { label: 'Pix Copia e Cola', icon: Copy }, { label: 'Cobrar', icon: CircleDollarSign }, { label: 'Depositar', icon: ArrowDownToLine },
]
const pixPreferences = [{ label: 'Pix automático', icon: RefreshCcw }, { label: 'Registrar ou trazer chaves', icon: Key }, { label: 'Meus limites', icon: SlidersHorizontal }]

function TransferFlow({ onBack, onClose }: { onBack: () => void; onClose: () => void }) {
  const [step, setStep] = useState<'selection' | 'amount' | 'confirm' | 'password' | 'transferring' | 'success'>('selection')
  const [recipient, setRecipient] = useState('')
  const [amount, setAmount] = useState('0,00')
  const [password, setPassword] = useState('')
  const [editingContact, setEditingContact] = useState<string | null>(null)
  const [contactDraft, setContactDraft] = useState('')
  const pressTimer = useRef<number | undefined>(undefined)
  const contacts = [{ initials: 'FV', name: 'Fábio Vieira', bank: 'RECARGAP...' }, { initials: 'FD', name: 'Flávio Duarto', bank: 'BANCO INT...' }, { initials: 'LF', name: 'Luís Fernando', bank: 'BCO C6 S.A.' }]
  const allContacts = [{ info: '59.429.182 Gucci Shopping Plazza', initials: '', bank: 'Conta bancária' }, { info: '61.315.182 Zara Shopping Plazza', initials: '', bank: 'Conta bancária' }, { info: 'Allan Almada Cunha', initials: 'AA', bank: 'Pix' }, { info: 'Bruno Henrique', initials: 'BH', bank: 'Pix' }]
  const selectRecipient = (name: string) => { setRecipient(name); setStep('amount') }
  const startEdit = (name: string) => { setEditingContact(name); setContactDraft(name) }
  const beginPress = (name: string) => { pressTimer.current = window.setTimeout(() => startEdit(name), 550) }
  const endPress = () => { if (pressTimer.current) window.clearTimeout(pressTimer.current) }
  const formattedAmount = amount.replace(/[^0-9,]/g, '')

  useEffect(() => { if (step !== 'transferring') return; const timers = [window.setTimeout(() => setStep('success'), 2800)]; return () => timers.forEach(window.clearTimeout) }, [step])
  const confirmPassword = (value: string) => { const digits = value.replace(/\D/g, '').slice(0, 4); setPassword(digits); if (digits.length === 4) setStep('transferring') }

  if (step === 'amount') return <div className="pix-screen transfer-overlay"><div className="pix-header"><button onClick={() => setStep('selection')}><ArrowLeft /></button></div><div className="pix-content transfer-content"><span className="muted">Transferir para</span><h1>{recipient || 'DESTINATÁRIO'}</h1><label className="pix-label">Valor</label><div className="pix-amount"><span>R$</span><input autoFocus inputMode="decimal" value={formattedAmount} onChange={(e) => setAmount(e.target.value)} placeholder="0,00" /></div><div className="payment-card"><Wallet size={30} /><div><strong>Saldo Nubank</strong><span>Atual: R$ 10.000,00</span></div></div><button className="pix-primary" onClick={() => setStep('confirm')}>Continuar com saldo</button></div></div>
  if (step === 'confirm') return <div className="pix-screen transfer-overlay"><div className="pix-header"><button onClick={() => setStep('amount')}><ArrowLeft /></button></div><div className="pix-content transfer-content"><h1>Você vai enviar</h1><div className="review-recipient"><span className="contact-avatar">{recipient.slice(0, 2).toUpperCase()}</span><div><strong>{recipient}</strong><span>Pix</span></div><button><MoreHorizontal /></button></div><div className="review-amount"><span>Valor total</span><strong>R$ {formattedAmount || '0,00'}</strong></div><button className="pix-primary" onClick={() => setStep('password')}>Enviar</button></div></div>
  if (step === 'password') return <div className="pix-screen transfer-overlay password-screen"><div className="pix-header"><button onClick={() => setStep('confirm')}><ArrowLeft /></button></div><div className="pix-content password-content"><h1>Digite sua senha de 4 dígitos</h1><p>Para confirmar esta transferência</p><input autoFocus className="password-input" type="password" inputMode="numeric" maxLength={4} value={password} onChange={(e) => confirmPassword(e.target.value)} /><div className="password-dots">{[0, 1, 2, 3].map((i) => <span className={password.length > i ? 'filled' : ''} key={i} />)}</div></div></div>
  if (step === 'transferring') return <div className="pix-screen transfer-overlay status-screen"><div className="status-spinner"><Loader2 size={30} /></div><h1>Transferindo...</h1><p>Estamos processando sua transferência</p><div className="progress-track"><span /></div></div>
  if (step === 'success') return <div className="pix-screen transfer-overlay success-screen"><div className="success-mark">✓</div><h1>Pronto!</h1><p>Transferência de R$ {formattedAmount || '0,00'} para {recipient} realizada.</p><button className="pix-primary" onClick={onClose}>Abrir comprovante</button></div>
  return <div className="pix-screen transfer-overlay"><div className="pix-header"><button onClick={onBack}><ArrowLeft /></button><button><MoreHorizontal /></button></div><div className="pix-content"><h1>Para quem você quer<br />transferir?</h1><label className="pix-label">Insira o dado de quem vai receber</label><div className="pix-search"><input autoFocus value={recipient} onChange={(e) => setRecipient(e.target.value)} placeholder="Nome, CPF/CNPJ ou chave Pix" /><QrCode size={22} /></div><h2>Você sempre costuma pagar</h2><div className="contact-row">{contacts.map((contact) => <button key={contact.name} onClick={() => selectRecipient(contact.name)} onPointerDown={() => beginPress(contact.name)} onPointerUp={endPress} onPointerLeave={endPress}><span>{contact.initials}</span><strong>{contact.name}</strong><small>{contact.bank}</small></button>)}</div><h2>Todos os seus contatos</h2><div className="all-contacts">{allContacts.map((contact) => <button key={contact.info} onClick={() => selectRecipient(contact.info)} onPointerDown={() => beginPress(contact.info)} onPointerUp={endPress} onPointerLeave={endPress}><span>{contact.initials || <Building2 size={22} />}</span><div><strong>{contact.info}</strong><small>{contact.bank}</small></div></button>)}</div>{recipient.trim() && <button className="pix-floating" onClick={() => selectRecipient(recipient)}><ArrowUpRight size={18} strokeWidth={2.5} /></button>}</div>{editingContact && <div className="contact-edit-backdrop"><form className="contact-edit-modal" onSubmit={(e) => { e.preventDefault(); setEditingContact(null) }}><button type="button" className="dialog-close" onClick={() => setEditingContact(null)}><X size={20} /></button><h2>Editar informações do contato</h2><label>Nome</label><input autoFocus value={contactDraft} onChange={(e) => setContactDraft(e.target.value)} /><button className="pix-primary" type="submit">Salvar</button></form></div>}</div>
}

function PixArea({ onClose }: { onClose: () => void }) {
  const [transfer, setTransfer] = useState(false)
  return <><div className="pix-screen"><div className="pix-header"><button onClick={onClose}><X size={28} strokeWidth={1.5} /></button><button><CircleQuestionMark size={24} strokeWidth={1.5} /></button></div><div className="pix-content"><h1>Área Pix</h1><p className="pix-description">Envie e receba pagamentos a qualquer hora e dia da semana, sem pagar nada por isso.</p><div className="pix-grid">{pixActions.map(({ label, icon: Icon }) => <div key={label}><button onClick={() => label === 'Transferir' && setTransfer(true)}><Icon size={26} strokeWidth={1.5} /></button><span>{label}</span></div>)}</div><h2>Preferências</h2><div className="pix-preferences">{pixPreferences.map(({ label, icon: Icon }) => <button key={label}><span><Icon size={22} strokeWidth={1.5} />{label}</span><ChevronRight size={20} /></button>)}</div><h2 className="support-title">Suporte</h2></div></div>{transfer && <TransferFlow onBack={() => setTransfer(false)} onClose={onClose} />}</>
}

function App() {
  const defaults: Values = { name: 'Seu Nome', balance: '10.000,00', invoice: '0,00', limit: '5.000,00', loan: '50.000,00' }
  const [values, setValues] = useState<Values>(() => {
    try {
      const saved = localStorage.getItem('nubank-values')
      if (!saved) return defaults
      const parsed = JSON.parse(saved) as Partial<Values>
      return { ...defaults, ...parsed }
    } catch {
      return defaults
    }
  })
  const [profileImage, setProfileImage] = useState(() => { try { return localStorage.getItem('nubank-profile-image') || '' } catch { return '' } })
  const [showBalance, setShowBalance] = useState(true)
  const [edit, setEdit] = useState<EditKey | null>(null)
  const [tab, setTab] = useState<keyof typeof bottomIcons>('home')
  const [pixOpen, setPixOpen] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  useEffect(() => { try { localStorage.setItem('nubank-values', JSON.stringify(values)) } catch { /* storage is optional */ } }, [values])
  useEffect(() => { try { profileImage ? localStorage.setItem('nubank-profile-image', profileImage) : localStorage.removeItem('nubank-profile-image') } catch { /* storage is optional */ } }, [profileImage])
  useEffect(() => { if ('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js').catch(() => undefined) }, [])
  const update = (key: EditKey, value: string) => setValues((current) => ({ ...current, [key]: value }))
  const chooseProfileImage = () => fileInputRef.current?.click()
  const onProfileImageChange = (event: ChangeEvent<HTMLInputElement>) => { const file = event.target.files?.[0]; if (!file) return; const reader = new FileReader(); reader.onload = () => setProfileImage(String(reader.result)); reader.readAsDataURL(file); event.target.value = '' }

  return <div className="app-shell">
    <header className="topbar">
      <div className="profile-block">
        <button className="avatar-button" onClick={chooseProfileImage} aria-label="Alterar foto de perfil"><div className="avatar">{profileImage ? <img src={profileImage} alt="Perfil" /> : <span className="profile-glyph">♙</span>}</div><span className="avatar-dot" /></button>
        <input ref={fileInputRef} type="file" accept="image/*" className="hidden-file" onChange={onProfileImageChange} />
        <div className="top-actions"><button onClick={() => setShowBalance((v) => !v)} aria-label="Mostrar ou ocultar saldo"><img src={showBalance ? 'https://i.imgur.com/ZdPpdvo.png' : 'https://i.imgur.com/ZeSsZ4i.png'} alt="" /></button><button aria-label="Ajuda"><HelpCircle size={22} /></button><button aria-label="Mensagens"><img src="https://i.imgur.com/7F6wazV.png" alt="" /></button></div>
        <button className="greeting" onClick={() => setEdit('name')}>Olá, <strong>{values.name}</strong></button>
      </div>
    </header>

    <main>
      <section className="balance-section" onClick={() => setEdit('balance')}><div className="section-heading"><h2>Saldo em conta</h2><MoreHorizontal size={19} /></div><div className="amount">{showBalance ? <>R$ {values.balance}</> : '••••'}</div><button className="pill-btn" onClick={(e) => e.stopPropagation()}><Plus size={14} /> Vincular conta</button></section>
      <section className="shortcut-row">{shortcuts.map((shortcut, index) => <button className="shortcut" key={shortcut.label} onClick={() => index === 0 && setPixOpen(true)}><span className="shortcut-icon"><img src={shortcut.icon} alt={shortcut.label.replace('\n', ' ')} />{shortcut.tag && <small>{shortcut.tag}</small>}</span><span>{shortcut.label}</span></button>)}</section>
      <section className="promo"><img src="https://i.imgur.com/DylQjZr.png" alt="Meus cartões" /><div><strong>Meus cartões</strong><span>Acesse seus cartões Nubank</span></div><ChevronRight size={19} /></section>
      <section className="section-card" onClick={() => setEdit('invoice')}><div className="section-heading"><h2>Cartão de crédito</h2><MoreHorizontal size={19} /></div><span className="muted">Fatura atual</span><div className="card-amount">{showBalance ? <>R$ {values.invoice}</> : '••••'}</div><span className="muted clickable" onClick={(e) => { e.stopPropagation(); setEdit('limit') }}>Limite disponível: {showBalance ? `R$ ${values.limit}` : '••••'}</span></section>
      <section className="loan-section"><div><span className="muted">Valor disponível de até</span><button className="link-value" onClick={() => setEdit('loan')}>{showBalance ? `R$ ${values.loan}` : '••••'}</button></div></section>
      <section className="discover"><h2>Descubra mais</h2><div className="card-scroller">{cards.map(([image, title, description, cta]) => <article className="discover-card" key={title}><img src={image} alt="" /><div><h3>{title}</h3><p>{description}</p><button>{cta}</button></div></article>)}</div></section>
    </main>

    <nav className="bottom-nav" aria-label="Navegação principal">{(Object.keys(bottomIcons) as Array<keyof typeof bottomIcons>).map((key) => <button key={key} className={tab === key ? 'active' : ''} onClick={() => setTab(key)} aria-label={key}><img src={bottomIcons[key]} alt="" /></button>)}</nav>
    {edit && <EditDialog kind={edit} value={values[edit]} onClose={() => setEdit(null)} onSave={(value) => update(edit, value)} />}
    {pixOpen && <PixArea onClose={() => setPixOpen(false)} />}
  </div>
}

export default App
