package com.pricecompare.model

/**
 * Android implementation of the common Decimal contract.
 * Uses java.math.BigDecimal, matching the existing jvmMain implementation.
 */
actual class Decimal actual constructor(value: String) {
    private val underlying: java.math.BigDecimal = java.math.BigDecimal(value)

    actual operator fun plus(other: Decimal): Decimal =
        Decimal((underlying + other.underlying).toPlainString())

    actual operator fun minus(other: Decimal): Decimal =
        Decimal((underlying - other.underlying).toPlainString())

    actual operator fun times(other: Decimal): Decimal =
        Decimal((underlying * other.underlying).toPlainString())

    actual operator fun div(other: Decimal): Decimal =
        Decimal(
            underlying.divide(other.underlying, 10, java.math.RoundingMode.HALF_UP)
                .toPlainString()
        )

    actual operator fun unaryMinus(): Decimal =
        Decimal(underlying.negate().toPlainString())

    actual fun compareTo(other: Decimal): Int =
        underlying.compareTo(other.underlying)

    actual fun stripTrailingZeros(): Decimal =
        Decimal(underlying.stripTrailingZeros().toPlainString())

    actual fun toPlainString(): String =
        underlying.stripTrailingZeros().toPlainString()

    override fun toString(): String = underlying.toString()

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Decimal) return false
        return underlying == other.underlying
    }

    override fun hashCode(): Int = underlying.hashCode()

    actual companion object {
        actual val ZERO: Decimal = Decimal("0")
        actual val ONE: Decimal = Decimal("1")
        actual fun fromLong(value: Long): Decimal = Decimal(value.toString())
    }
}
